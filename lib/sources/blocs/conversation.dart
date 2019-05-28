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

  // TODO: replace with FirechatUser
  BehaviorSubject<List<String>> _composingUsersController =
      BehaviorSubject<List<String>>.seeded([]);

  /// The [Stream] for the list of users that are currently typing a message.
  ///
  /// Note : this list excludes the current user.
  Observable<List<String>> get onComposingUsersUpdate =>
      _composingUsersController.stream;

  // TODO: replace with FirechatUser
  BehaviorSubject<List<String>> _focusingUsersController =
      BehaviorSubject<List<String>>.seeded([]);
  // TODO: add a Configuration item to set if the current user should be counted or not as a focusing user in this stream

  /// The [Stream] for the list of users that are currently in the chatroom.
  ///
  /// Note : this list excludes the current user by default, but it can be
  /// changed in the configuration of [FirechatKit].
  Observable<List<String>> get onFocusingUsersUpdate =>
      _focusingUsersController.stream;

  /// The list of all the [Stream] currently listening
  /// for [FirechatMessage]s.
  List<Stream<List<DocumentSnapshot>>> _streams = [];

  /// The last lists of [FirechatMessage]s that each [Stream]
  /// has returned.
  Map<Stream<List<DocumentSnapshot>>, List<FirechatMessage>>
      _listenersMessagesList = {};

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
    FirestoreChatroomInterface.chatroomStreamFor(
            chatroomRef: _chatroom.selfReference)
        .listen((DocumentSnapshot snap) {
      if (snap == null || !snap.exists) return null;

      // Chatroom Stream update
      _chatroom = FirechatChatroom.fromMap(snap.data, snap.reference);
      _chatroomController.sink.add(_chatroom);

      // Composing users Stream update
      // TODO: replace with FirechatUser
      List<DocumentReference> otherPeopleComposing = _chatroom
          .composingPeopleRef
          .where((DocumentReference ref) => ref != _authorRef)
          .toList();
      _composingUsersController.sink
          .add(List<String>.filled(otherPeopleComposing.length ?? 0, "People"));

      // Focusing users Stream update
      // TODO: replace with FirechatUser
      // TODO: handle configuration item to know if the current user should be excluded from this list.
      List<DocumentReference> peopleFocusing = _chatroom.focusingPeopleRef
          .where((DocumentReference ref) => ref != _authorRef)
          .toList();
      _focusingUsersController.sink
          .add(List<String>.filled(peopleFocusing.length ?? 0, "People"));
    });

    // Gets and listens to the stream of messages related to the Chatroom.
    Stream<List<DocumentSnapshot>> _lastListener =
        await FirestoreMessageInterface.streamForRecentAndFutureMessagesIn(
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
        await FirestoreMessageInterface.streamForOlderMessages(
            chatroomReference: _chatroom.selfReference);
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
  void _updateSinkWithMessages() {
    List<FirechatMessage> messagesToSort = [];
    _listenersMessagesList.values.forEach(
        (List<FirechatMessage> messages) => messagesToSort.addAll(messages));
    _messagesController.add(_orderedByDate(list: messagesToSort));
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

    await FirestoreChatroomInterface.setUserFocusing(
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

    await FirestoreChatroomInterface.setUserIsComposing(
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

    await FirestoreMessageInterface.send(messageToSend);
    await FirestoreChatroomInterface.updateLastMessageDateFor(
        chatroom: _chatroom, date: messageToSend.date);
  }

  /// Deletes the given [message].
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> deleteMessage(FirechatMessage message) async {
    await FirestoreMessageInterface.delete(message).catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kMessageDeletionError;
    });
  }

  /// Exports the [FirechatChatroom] to Firestore.
  ///
  /// This allows to then set up the [Stream]s and to follow the updates related
  /// to the conversation.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> _createConversationAndStream() async {
    _chatroom =
        await FirestoreChatroomInterface.exportToFirestore(chatroom: _chatroom)
            .catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kFirestoreChatroomUploadError;
    });
    _streamChatroomAndFirstMessages();
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
