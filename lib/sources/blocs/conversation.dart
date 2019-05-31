part of firechat_kit;

class FirechatConversation {
  DocumentReference _authorRef;

  BehaviorSubject<FirechatChatroom> _chatroomController;
  Observable<FirechatChatroom> get onChatroomUpdate =>
      _chatroomController.stream;
  FirechatChatroom _chatroom;

  DocumentReference get chatroomReference => _chatroom.selfReference;

  BehaviorSubject<List<FirechatMessage>> _messagesController;
  Observable<List<FirechatMessage>> get onMessagesUpdate =>
      _messagesController.stream;

  FirechatMessage _mostRecentMessage;

  // TODO: set contacts stream
  BehaviorSubject<List<FirechatUser>> _contactsController;
  Observable<List<FirechatUser>> get onContactsUpdate =>
      _contactsController.stream;
  List<FirechatUser> _contactsList = [];
  List<FirechatUser> get contactsList => contactsList;

  BehaviorSubject<List<FirechatUser>> _composingUsersController =
      BehaviorSubject<List<FirechatUser>>.seeded([]);

  /// The [Stream] for the list of users that are currently typing a message.
  ///
  /// Note : this list excludes the current user.
  Observable<List<FirechatUser>> get onComposingUsersUpdate =>
      _composingUsersController.stream;

  BehaviorSubject<List<FirechatUser>> _focusingUsersController =
      BehaviorSubject<List<FirechatUser>>.seeded([]);

  /// The [Stream] for the list of users that are currently in the chatroom.
  ///
  /// Note : this list excludes the current user by default, but it can be
  /// changed in the configuration of [FirechatKit].
  Observable<List<FirechatUser>> get onFocusingUsersUpdate =>
      _focusingUsersController.stream;

  /// The list of all the [Stream] currently listening
  /// for [FirechatMessage]s.
  List<Stream<List<DocumentSnapshot>>> _streams = [];

  /// The last lists of [FirechatMessage]s that each [Stream]
  /// has returned.
  Map<Stream<List<DocumentSnapshot>>, List<FirechatMessage>>
      _listenersMessagesList = {};
  List<FirechatMessage> get _allStreamedMessages =>
      _listenersMessagesList.values.expand((x) => x).toList();

  // ###########################
  // METHODS
  // ###########################

  //
  // ########### CONSTRUCTORS
  //

  FirechatConversation.local(
      {@required FirechatChatroom chatroom,
      @required DocumentReference currentUserRef})
      : _messagesController = BehaviorSubject<List<FirechatMessage>>.seeded([]),
        _chatroomController =
            BehaviorSubject<FirechatChatroom>.seeded(chatroom) {
    _chatroom = chatroom;
    _authorRef = currentUserRef;
  }

  FirechatConversation.streamed(
      {@required FirechatChatroom chatroom,
      @required DocumentReference currentUserRef})
      : _messagesController = BehaviorSubject<List<FirechatMessage>>(),
        _chatroomController =
            BehaviorSubject<FirechatChatroom>.seeded(chatroom) {
    _chatroom = chatroom;
    _authorRef = currentUserRef;
    _streamChatroomAndFirstMessages();
  }

  void dispose() async {
    await _messagesController.drain();
    _messagesController.close();
    await _chatroomController.drain();
    _chatroomController.close();
    await _composingUsersController.drain();
    _composingUsersController.close();
    await _focusingUsersController.drain();
    _focusingUsersController.close();
    await _contactsController.drain();
    _contactsController.close();
  }

  //
  // ########### PAGINATED STREAMS

  /// Installs the [Stream] for the [FirechatChatroom], and the [Stream] for
  /// the most recent [FirechatMessage]s and the ones that will be published
  /// after the [Stream] begins to listen.
  ///
  /// To request older messages, call [requestOlderMessages].
  Future<void> _streamChatroomAndFirstMessages() async {
    // Gets and listens to the stream of the Chatroom.
    FirestoreChatroomInterface()
        .chatroomStreamFor(chatroomRef: _chatroom.selfReference)
        .listen((DocumentSnapshot snap) {
      if (snap == null || !snap.exists) return null;

      // Chatroom Stream update
      _chatroom = FirechatChatroom.fromMap(snap.data, snap.reference);
      _chatroomController.sink.add(_chatroom);

      _updateComposingAndFocusingLists();
    });

    // Gets and listens to the stream of messages related to the Chatroom.
    Stream<List<DocumentSnapshot>> _lastListener =
        await FirestoreMessageInterface().streamForRecentAndFutureMessagesIn(
            chatroomReference: _chatroom.selfReference);

    if (_lastListener == null) return;
    _addListenerFor(messagesStream: _lastListener);
    _streams.add(_lastListener);
  }

  /// Creates a new listener for the older [FirechatMessage]s documents that
  /// are not listened to by the last instantiated listener.
  ///
  /// If there is no more message to listen to, the function returns without
  /// changing any stream.
  Future<void> requestOlderMessages() async {
    Stream<List<DocumentSnapshot>> _nextListener =
        await FirestoreMessageInterface()
            .streamForOlderMessages(chatroomReference: _chatroom.selfReference);
    if (_nextListener == null) return;
    _addListenerFor(messagesStream: _nextListener);
    _streams.add(_nextListener);
  }

  /// Sets up the subscription for the given [messagesStream] so as to handle
  /// the incomming messages.
  void _addListenerFor(
      {@required Stream<List<DocumentSnapshot>> messagesStream}) {
    messagesStream.listen((List<DocumentSnapshot> snapshots) {
      List<FirechatMessage> messages = snapshots
          .map((DocumentSnapshot snap) =>
              FirechatMessage.fromMap(snap.data, snap.reference))
          .toList();
      _listenersMessagesList[messagesStream] = messages;
      _updateSinkWithMessages();
    });
  }

  /// Gathers all the [FirechatMessage] instances from all the currently active
  /// listeners, sorts them by descending dates and feeds the
  /// [_messagesController]'s sink with the complete result.
  ///
  /// Also call [_markMessagesAsReadIfFocusing] if the automation process has
  /// been configured.
  Future<void> _updateSinkWithMessages() async {
    List<FirechatMessage> messagesToSort = [];
    _listenersMessagesList.values.forEach(
        (List<FirechatMessage> messages) => messagesToSort.addAll(messages));
    List<FirechatMessage> orderedMessages =
        _orderedByDate(list: messagesToSort);

    _mostRecentMessage = orderedMessages.first;

    await _updateContactsList();

    _updateComposingAndFocusingLists();

    _messagesController.add(orderedMessages);

    await _markMessagesAsReadIfFocusing();
  }

  void _updateComposingAndFocusingLists() {
    // Composing users Stream update
    List<DocumentReference> otherPeopleComposing = _chatroom.composingPeopleRef
        .where((DocumentReference ref) => ref != _authorRef)
        .toList();
    _composingUsersController.sink.add(_contactsList
        .where((FirechatUser user) =>
            otherPeopleComposing.contains(user.selfReference))
        .toList());

    // Focusing users Stream update
    List<DocumentReference> peopleFocusing =
        _chatroom.focusingPeopleRef.where((DocumentReference ref) {
      if (FirechatKit.instance.configuration.countCurrentUSerInFocusList)
        return true;
      return (ref != _authorRef);
    }).toList();
    _focusingUsersController.sink.add(_contactsList
        .where(
            (FirechatUser user) => peopleFocusing.contains(user.selfReference))
        .toList());
  }

  //
  // ########## CONTACTS INFORMATIONS
  //

  /// Based on the streamed messages, all the [FirechatUser] of the conversation
  /// are fetched to be available.
  ///
  /// Is called each time the list of streamed messages is updated.
  Future<void> _updateContactsList() async {
    // The list of all the contacts that are senders of the currently streamed
    // messages.
    List<DocumentReference> listOfContacts = [];
    _allStreamedMessages.forEach((FirechatMessage message) {
      if (message.authorRef != null &&
          !listOfContacts.contains(message.authorRef))
        listOfContacts.add(message.authorRef);
    });

    // The instances that are not to be streamed (not anymore among the
    // senders) are removed.
    _contactsList.forEach((FirechatUser user) {
      if (!listOfContacts.contains(user.selfReference))
        _contactsList.remove(user);
    });

    // The instances that are not yet in _contactsList are fetched.
    List<DocumentReference> contactsToFetchReferences = listOfContacts
        .where((DocumentReference userRef) => _contactsList
            .where((FirechatUser user) => user.selfReference == userRef)
            .isEmpty)
        .toList();
    List<Future<DocumentSnapshot>> fetchingTasks = contactsToFetchReferences
        .map((DocumentReference ref) =>
            FirestoreUserInterface().userFromReference(ref: ref))
        .toList();
    await Future.wait(fetchingTasks).then((List<DocumentSnapshot> snapshots) {
      snapshots.forEach((DocumentSnapshot snap) =>
          _contactsList.add(FirechatUser.fromMap(snap.data, snap.reference)));
    });
  }

  /// Returns the [FirechatUser] who sent the [message].
  ///
  /// If none is found, null is returned.
  FirechatUser senderOf({@required FirechatMessage message}) {
    return _contactsList.firstWhere(
        (FirechatUser user) => user.selfReference == message.authorRef,
        orElse: () => null);
  }

  //
  // ########## COMPOSING & FOCUSING PROCESS
  //

  /// Adds or removes the current user from the list of people who are currently
  /// focusing the [FirechatChatroom] accordingly to [isFocusing].
  ///
  /// This indicates if the user is in the chatroom, and thus if they
  /// can see the new messages and updates in realtime.
  ///
  /// If an error occurs, a [FirechatError] is thrown
  Future<void> userIsFocusing(bool isFocusing) async {
    if (_chatroom.isLocal || _chatroom.selfReference == null) return;
    // No need to call Firestore when its not needed.
    if ((isFocusing && _chatroom.focusingPeopleRef.contains(_authorRef) ||
        (!isFocusing && !_chatroom.focusingPeopleRef.contains(_authorRef))))
      return;

    await FirestoreChatroomInterface()
        .setUserFocusing(
            chatroom: _chatroom,
            userReference: _authorRef,
            isFocusing: isFocusing)
        .catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }

  /// Adds or removes the current user from the list of people who are currently
  /// composing / typing a message in the [FirechatChatroom] accordingly
  /// to [isComposing].
  ///
  /// If an error occurs, a [FirechatError] is thrown
  Future<void> userIsComposing(bool isComposing) async {
    if (_chatroom.isLocal || _chatroom.selfReference == null) return;
    // No need to call Firestore when its not needed.
    if ((isComposing && _chatroom.composingPeopleRef.contains(_authorRef) ||
        (!isComposing && !_chatroom.composingPeopleRef.contains(_authorRef))))
      return;

    await FirestoreChatroomInterface()
        .setUserIsComposing(
            chatroom: _chatroom,
            userReference: _authorRef,
            isComposing: isComposing)
        .catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }

  //
  // ########## ACTIONS
  //

  /// Creates a new instance of [FirechatMessage] and publishes it in Firestore.
  ///
  /// If the [_chatroom] was local so far (that is not published), it is
  /// published before the message is sent.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> sendMessage(String content,
      {String assetUrl, FirechatMessageAssetType assetType}) async {
    // The content of the message is checked to avoid empty messages.
    content.trim();
    if (content.length < 1) throw FirechatError.kMessageToSendIsEmpty;
    if (assetUrl != null && assetUrl.isNotEmpty && assetType == null)
      throw FirechatError.kMessageAssetTypeIsNull;

    // If the chatroom was local so far, it is first exported to Firestore.
    if (_chatroom.isLocal) await _createConversationAndStream();

    // The message is created once the chatroom has a reference in Firestore.
    FirechatMessage messageToSend = FirechatMessage(
        authorRef: _authorRef,
        chatroomRef: _chatroom.selfReference,
        content: content,
        assetUrl: assetUrl,
        assetType: assetType,
        date: DateTime.now());

    await FirestoreMessageInterface().send(messageToSend);
    await FirestoreChatroomInterface()
        .updateLastMessageFor(chatroom: _chatroom, message: messageToSend);
  }

  /// Deletes the given [message].
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> deleteMessage(FirechatMessage message) async {
    await FirestoreMessageInterface().delete(message).catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kMessageDeletionError;
    });
  }

  /// Updates the [FirechatChatroom.lastMessagesRead] to indicate that the last
  /// message the current user has read is the most recent, thus indicating
  /// that all the previous messages are read as well.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> currentUserReadAllMessages() async {
    if (_mostRecentMessage == null) return;
    FirestoreChatroomInterface()
        .setLastReadMessageForUser(
            userRef: _authorRef,
            chatroom: _chatroom,
            message: _mostRecentMessage)
        .catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kFirestoreChatroomLastMessageUpdaterror;
    });
  }

  /// Exports the [FirechatChatroom] to Firestore.
  ///
  /// This allows to then set up the [Stream]s and to follow the updates related
  /// to the conversation.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> _createConversationAndStream() async {
    _chatroom = await FirestoreChatroomInterface()
        .exportToFirestore(chatroom: _chatroom)
        .catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kFirestoreChatroomUploadError;
    });
    _streamChatroomAndFirstMessages();
  }

  //
  // ########## READ RECEIPT AUTOMATION
  //

  /// If the current user is currently focusing the conversation, the messages
  /// will be marked as read.
  Future<void> _markMessagesAsReadIfFocusing() async {
    if (!_chatroom.focusingPeopleRef.contains(_authorRef)) return;

    await currentUserReadAllMessages();
  }

  Future<void> markMessagesAsRead() async {
    if (FirechatKit.instance.configuration.automaticallyReadMessages &&
        _chatroom.focusingPeopleRef.contains(_authorRef))
      print(
          """FirechatKit is configured to automatically mark the messages as read when the current user is focusing the chatroom.
          [FirechatConversation.markMessagesAsRead()] has been called while the current user was focusing the chatroom.
          While this does not affect the behaviour of Firechat, a Firestore request is performed twice, which is unnécessary.
          You may want to check and remove unnecessary calls to this method. 
          """);
    await currentUserReadAllMessages();
  }

  //
  // ########## HELPERS
  //

  /// Indicates if the given [message] has been read by at least someone other
  /// than the author.
  ///
  /// [message] is expected to be one of the currently streamed messages, so as
  /// to if the last seen messages of the other members of the chatrooms cannot
  /// be found among the streamed ones, it will be considered anterior.
  bool messageIsReadByOthers(FirechatMessage message) {
    List<DocumentReference> lastSeenMessageRefForOthers = _chatroom
        .lastMessagesRead.keys
        .where((DocumentReference ref) => ref != _authorRef)
        .map((DocumentReference otherUserRef) =>
            _chatroom.lastMessagesRead[otherUserRef])
        .toList();
    List<FirechatMessage> lastSeenMessages = lastSeenMessageRefForOthers
        .map((DocumentReference msgRef) => _allStreamedMessages.firstWhere(
            (FirechatMessage candidate) => candidate.selfReference == msgRef,
            orElse: () => null))
        .where((item) => item != null)
        .toList();
    return lastSeenMessages.any((FirechatMessage candidate) =>
        candidate.date.isAfter(message.date) ||
        candidate.selfReference == message.selfReference);
  }

  //
  // ########## CHATROOM DETAILS
  //

  /// Sets the given [map] to [_chatroom.details] and uploads the field to
  /// Firestore.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> setChatroomDetails({@required Map<String, dynamic> map}) async {
    await FirestoreChatroomInterface()
        .updateChatroomDetails(chatroom: _chatroom)
        .catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }

  //
  // ########## CONVERSATION NAME
  //

  /// Sets the given [name] as the [_chatroom.title] and uploads the field to
  /// Firestore.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> setChatroomName({@required String name}) async {
    await FirestoreChatroomInterface()
        .updateChatroomName(name: name, chatroomRef: _chatroom.selfReference)
        .catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }

  //
  // ########## SORTING
  //

  /// Orders the given [list] from the newer message to the oldest.
  ///
  /// This order is meant to be used in pair with a *reversed* [ListView]
  /// (or any list widget).
  List<FirechatMessage> _orderedByDate({@required List<FirechatMessage> list}) {
    return list
      ..sort((m1, m2) {
        return -m1.date.compareTo(m2.date);
      });
  }
}
