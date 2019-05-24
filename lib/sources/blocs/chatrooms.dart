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
  List<FirechatChatroom> _chatrooms;

  /// The [Map] of users associated with each [FirechatChatroom].
  ///
  /// This is to be used to get the data relative to the other user for each
  /// conversation.
  Map<DocumentReference, FirechatUser> _usersByChatroom = {};
  Map<DocumentReference, FirechatUser> get usersByChatroom => _usersByChatroom;

  /// The [Map] of the last messages for each [FirechatChatroom].
  Map<DocumentReference, FirechatMessage> _lastMessagesByChatroom;

  FirechatChatrooms({@required this.userDocumentReference}) {
    prepare();
  }

  void prepare() {
    // Gets the Stream for the Chatroom documents from Firestore and maps the
    // result to a list of Chatroom instances, that is added to
    // _chatroomController.
    FirestoreChatroomInterface.chatroomsForUser(
            userReference: userDocumentReference)
        .listen((List<DocumentSnapshot> documents) async {
      if (documents == null) return;
      _chatrooms = documents.map((DocumentSnapshot snap) {
        return FirechatChatroom.fromMap(snap.data, snap.reference);
      }).toList();
      await _updateUsersByChatroomMap();
      // TODO: get the profiles and the last messages
      _chatroomsController.add(_chatrooms);
    });
  }

  void dispose() async {
    await _chatroomsController.drain();
    _chatroomsController.close();
  }

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
        await FirestoreChatroomInterface.privateChatroomBetween(
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
        composingPeopleRef: [],
        focusingPeopleRef: [],
        isLocal: true);
    return FirechatConversation.local(
        chatroom: localChatroom, currentUserRef: userDocumentReference);
  }

  Future<void> _updateUsersByChatroomMap() async {
    // Removing the entries for conversations that are not in _chatrooms
    // since the previous update.
    if (_usersByChatroom == null) return;

    _usersByChatroom.removeWhere((DocumentReference chatroomRef, _) =>
        !_chatrooms.any((FirechatChatroom chatroom) =>
            chatroom.selfReference == chatroomRef));

    // Adds the entries for conversations that were not in _chatrooms
    // on the last update.
    List<FirechatChatroom> newInstancesSinceUpdate = _chatrooms
        .where((FirechatChatroom chatroom) =>
            !_usersByChatroom.keys.contains(chatroom.selfReference))
        .toList();
    await Future.forEach(newInstancesSinceUpdate,
        (FirechatChatroom chatroom) async {
      // TODO: handle how to handle this for a group conversation
      DocumentReference contactRef = chatroom.peopleRef
          .where((DocumentReference ref) => ref != userDocumentReference)
          .toList()
          .first;
      _usersByChatroom[chatroom.selfReference] =
          await FirestoreUserInterface.userFromReference(ref: contactRef)
              .then((DocumentSnapshot snap) =>
                  FirechatUser.fromMap(snap.data, snap.reference))
              .catchError((e) {
        print(e);
        return null;
      });
    });
  }
}
