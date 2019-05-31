part of firechat_kit;

class FirechatChatrooms {
  /// The [DocumentReference] of the user all the [FirechatChatroom]s are to be
  /// linked to.
  DocumentReference userDocumentReference;

  BehaviorSubject<List<FirechatChatroom>> _chatroomsController =
      BehaviorSubject<List<FirechatChatroom>>.seeded([]);
  Observable<List<FirechatChatroom>> get onChatroomsUpdate =>
      _chatroomsController.stream;

  /// The last state of the [FirechatChatroom]s related to the current user.
  List<FirechatChatroom> _chatrooms = [];

  /// The [Map] of users associated with each [FirechatChatroom].
  ///
  /// This is to be used to get the data relative to the other user for each
  /// conversation.
  Map<DocumentReference, List<FirechatUser>> _usersByChatroom = {};

  /// The [Map] of the last messages for each [FirechatChatroom].
  Map<DocumentReference, FirechatMessage> _lastMessagesByChatroom;

  /// The list of [Stream]s currently listening for the [FirechatChatroom]
  /// instances the current user takes part to.
  List<Stream<List<DocumentSnapshot>>> _streams = [];

  /// The last list of [FirechatChatroom]s that each [Stream] has returned.
  Map<Stream<List<DocumentSnapshot>>, List<FirechatChatroom>>
      _listenersChatroomsList = {};

  FirechatChatrooms({@required this.userDocumentReference}) {
    prepare();
  }

  void prepare() {
    _streamFirstChatrooms();
  }

  void dispose() async {
    await _chatroomsController.drain();
    _chatroomsController.close();
  }

  //
  // ########## PAGINATED STREAMS
  //

  /// Installs the [Stream] for the most recent [FirechatChatroom]s and the ones
  /// that will be published after the [Stream] begins to listen.
  ///
  /// To request older messages, call [requestOlderChatrooms].
  Future<void> _streamFirstChatrooms() async {
    // Gets the Stream for the Chatroom documents from Firestore and maps the
    // result to a list of Chatroom instances, that is added to
    // _chatroomController.
    Stream<List<DocumentSnapshot>> lastListener =
        await FirestoreChatroomInterface().streamForRecentAndFutureChatroomsFor(
            userReference: userDocumentReference);
    if (lastListener == null) return;
    _addListenerFor(chatroomsStream: lastListener);
    _streams.add(lastListener);
  }

  /// Creates a new listener for the older [FirechatMessage]s documents that
  /// are not listened to by the last instantiated listener.
  ///
  /// If there is no more message to listen to, the function returns without
  /// changing any stream.
  Future<void> requestOlderChatrooms() async {
    Stream<List<DocumentSnapshot>> nextListener =
        await FirestoreChatroomInterface().streamOlderChatroomsFor(
            userReference: userDocumentReference);
    if (nextListener == null) return;
    _addListenerFor(chatroomsStream: nextListener);
    _streams.add(nextListener);
  }

  /// Sets up the subscription for the given [chatroomsStream] so as to handle
  /// the chatrooms updates.
  void _addListenerFor(
      {@required Stream<List<DocumentSnapshot>> chatroomsStream}) {
    chatroomsStream.listen((List<DocumentSnapshot> snapshots) {
      if (snapshots == null) return null;
      List<FirechatChatroom> chatrooms = snapshots
          .map((DocumentSnapshot snap) =>
              FirechatChatroom.fromMap(snap.data, snap.reference))
          .toList();
      _listenersChatroomsList[chatroomsStream] = chatrooms;
      _updateSinkWithChatrooms();
    });
  }

  /// Gathers all the [FirechatChatroom] instances from all the currently active
  /// listeners, sorts them by descending dates and feeds the
  /// [_chatroomsController]'s sink with the complete result.
  Future<void> _updateSinkWithChatrooms() async {
    List<FirechatChatroom> chatroomsToSort = [];
    _listenersChatroomsList.values.forEach((List<FirechatChatroom> chatrooms) =>
        chatroomsToSort.addAll(chatrooms));

    await _updateUsersByChatroomMapUsing(chatrooms: chatroomsToSort);
    await _updateLastMessagesByChatroomUsing(chatrooms: chatroomsToSort);

    _chatroomsController.add(_orderedByDate(list: chatroomsToSort));
  }

  //
  // ########## CONVERSATION
  //

  /// Returns the [FirechatConversation] of the conversation between the current
  /// user and the contact designated by their [contactRef], that is the
  /// [DocumentReference] of the [FirechatUser] document in Firestore related
  /// to this contact.
  ///
  /// This should be used only for private conversations (1 to 1 conversations)
  /// between 2 users.
  ///
  /// If an error occurs, a [FirechatError] is returned.
  Future<FirechatConversation> getConversationWithUser(
      {@required DocumentReference contactRef}) async {
    // Search for an existing conversation between the two users.
    FirechatChatroom candidate =
        await FirestoreChatroomInterface().privateChatroomBetween(
                firstUserRef: userDocumentReference, secondUserRef: contactRef)
            .catchError((e) {
      if (e is FirechatError) throw e;
      print(e);
      throw FirechatError.kChatroomQueryError;
    });
    if (candidate != null)
      return FirechatConversation.streamed(
          chatroom: candidate, currentUserRef: userDocumentReference);

    // No candidate has been found : a new conversation is to be created.
    FirechatChatroom localChatroom = FirechatChatroom(
        chatroomType: FirechatChatroomType.oneToOne,
        peopleRef: [userDocumentReference, contactRef],
        lastMessageDate: DateTime.now(),
        composingPeopleRef: [],
        focusingPeopleRef: [],
        lastMessagesRead: {userDocumentReference: null, contactRef: null},
        isLocal: true);
    return FirechatConversation.local(
        chatroom: localChatroom, currentUserRef: userDocumentReference);
  }

  //
  // ########## CHATROOM RELATED DATA FETCHING
  //

  /// Updates [_usersByChatroom] for the currently streamed chatrooms.
  Future<void> _updateUsersByChatroomMapUsing(
      {@required List<FirechatChatroom> chatrooms}) async {
    if (_usersByChatroom == null) _usersByChatroom = {};

    // Removing the entries for conversations that are not in _chatrooms
    // since the previous update.
    _usersByChatroom.removeWhere((DocumentReference chatroomRef, _) =>
        !chatrooms.any((FirechatChatroom chatroom) =>
            chatroom.selfReference == chatroomRef));

    // Gets the entries for conversations that were not in _chatrooms
    // on the last update.
    List<FirechatChatroom> newInstancesSinceUpdate = chatrooms
        .where((FirechatChatroom chatroom) =>
            !_usersByChatroom.keys.contains(chatroom.selfReference))
        .toList();

    /// For each new instance, the [FirechatUser] who takes part in it is
    /// fetched.
    await Future.forEach(newInstancesSinceUpdate,
        (FirechatChatroom chatroom) async {
      List<DocumentReference> contactsRef = chatroom.peopleRef
          .where((DocumentReference ref) => ref != userDocumentReference)
          .toList();

      List<FirechatUser> users = [];
      await Future.forEach(contactsRef, (DocumentReference contactRef) async {
        FirechatUser user = await FirestoreUserInterface()
            .userFromReference(ref: contactRef)
            .then((DocumentSnapshot snap) =>
                FirechatUser.fromMap(snap.data, snap.reference));
        users.add(user);
      });
      _usersByChatroom[chatroom.selfReference] = users;
    });
  }

  /// Updates [_lastMessagesByChatroom] for the currently streamed chatrooms.
  Future<void> _updateLastMessagesByChatroomUsing(
      {@required List<FirechatChatroom> chatrooms}) async {
    if (_lastMessagesByChatroom == null) _lastMessagesByChatroom = {};

    // Removing the entries for the conversations that are not in the list, that
    // is not streamed anymore.
    _lastMessagesByChatroom.removeWhere((DocumentReference chatroomRef, _) =>
        !chatrooms.any((FirechatChatroom chatroom) =>
            chatroom.selfReference == chatroomRef));

    // An update is required when the chatroom has no reference in
    // _lastMessagesByChatroom or when the related reference is not the same
    // as [chatroom.lastMessageRef].
    List<FirechatChatroom> chatroomsWithUpdateRequired = chatrooms
        .map((FirechatChatroom chatroom) {
          if (_lastMessagesByChatroom[chatroom.selfReference] == null)
            return chatroom;
          if (_lastMessagesByChatroom[chatroom.selfReference].selfReference !=
              chatroom.lastMessageRef) return chatroom;
          return null;
        })
        .where((FirechatChatroom item) => item != null)
        .toList();

    await Future.forEach(chatroomsWithUpdateRequired,
        (FirechatChatroom chatroom) async {
      if (chatroom.lastMessageRef == null) return null;
      FirechatMessage message = await FirestoreMessageInterface()
          .messageFor(reference: chatroom.lastMessageRef);
      _lastMessagesByChatroom[chatroom.selfReference] = message;
    });
  }

  //
  // ######### CHATROOM-RELATED DATA
  //

  /// Returns the last [FirechatMessage] that was sent in the given
  /// [chatroom].
  ///
  /// If none is found, null is returned.
  FirechatMessage lastMessageFor({@required FirechatChatroom chatroom}) {
    return _lastMessagesByChatroom[chatroom.selfReference];
  }

  /// Returns the list of [FirechatUser] who take part in the [chatroom].
  ///
  /// This list does not include the current user.
  ///
  /// If none is found, an empty list is returned.
  List<FirechatUser> otherPeopleIn({@required FirechatChatroom chatroom}) {
    return _usersByChatroom[chatroom.selfReference] ?? [];
  }

  /// Indicates if the last message of the [chatroom] has not been read yet
  /// by the current user.
  bool currentUserHasUnreadIn({@required FirechatChatroom chatroom}) {
    // Firechat follows a principle saying that if a given message is
    // read, all the previous ones are read.
    // This way, if the last message of the given chatroom is read by the
    // current user, they are up to date.
    //
    // First case : no reference of the current user : they have read no
    // messages.
    if (chatroom.lastMessagesRead[userDocumentReference] == null) return false;
    return (chatroom.lastMessagesRead[userDocumentReference] !=
        chatroom.lastMessageRef);
  }

  //
  // ######### SORTING
  //

  /// Orders the given [list] from the chatroom updated the most recently to
  /// the latest to be updated.
  List<FirechatChatroom> _orderedByDate(
      {@required List<FirechatChatroom> list}) {
    return list
      ..sort((c1, c2) {
        return -c1.lastMessageDate.compareTo(c2.lastMessageDate);
      });
  }
}
