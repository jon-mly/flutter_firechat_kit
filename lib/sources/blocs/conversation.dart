part of firechat_kit;

class FirechatConversation {
  DocumentReference _authorRef;

  BehaviorSubject<FirechatChatroom> _chatroomController =
      BehaviorSubject<FirechatChatroom>();
  Observable<FirechatChatroom> get onChatroomUpdate =>
      _chatroomController.stream;
  FirechatChatroom _chatroom;

  DocumentReference get chatroomReference => _chatroom.selfReference;

  BehaviorSubject<List<FirechatMessage>> _messagesController;
  Observable<List<FirechatMessage>> get onMessagesUpdate =>
      _messagesController.stream;

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
      : _messagesController =
            BehaviorSubject<List<FirechatMessage>>.seeded([]) {
    _chatroom = chatroom;
    _authorRef = currentUserRef;
  }

  FirechatConversation.streamed(
      {@required FirechatChatroom chatroom,
      @required DocumentReference currentUserRef})
      : _messagesController = BehaviorSubject<List<FirechatMessage>>() {
    _chatroom = chatroom;
    _authorRef = currentUserRef;
    _streamFirstMessages();
  }

  //
  // ########### PAGINATED STREAMS

  /// Installs the [Stream] for the [FirechatChatroom], and the [Stream] for
  /// the most recent [FirechatMessage]s and the ones that will be published
  /// after the [Stream] begins to listen.
  ///
  /// To request older messages, call [requestOlderMessages].
  Future<void> _streamFirstMessages() async {
    // Gets and listens to the stream of the Chatroom.
    FirestoreChatroomInterface.chatroomStreamFor(
            chatroomRef: _chatroom.selfReference)
        .listen((DocumentSnapshot snap) {
      if (snap == null || !snap.exists) return null;
      _chatroomController.sink
          .add(FirechatChatroom.fromMap(snap.data, snap.reference));
    });

    // Gets and listens to the stream of messages related to the Chatroom.
    Stream<List<DocumentSnapshot>> _lastListener =
        await FirestoreMessageInterface.streamForRecentAndFutureMessagesIn(
            chatroomReference: _chatroom.selfReference);
    _lastListener.listen((List<DocumentSnapshot> snapshots) {
      List<FirechatMessage> messages = snapshots
          .map((DocumentSnapshot snap) =>
              FirechatMessage.fromMap(snap.data, snap.reference))
          .toList();
      _listenersMessagesList[_lastListener] = messages;
      _updateSinkWithMessages();
    });
    _streams.add(_lastListener);
  }

  /// Creates a new listener for the older [FirechatMessage]s documents that
  /// are not listened to by the last instantiated listener.
  ///
  /// If there is no more message to listen to, the
  Future<void> requestOlderMessages() async {
    Stream<List<DocumentSnapshot>> _nextListener =
        await FirestoreMessageInterface.streamForOlderMessages(
            chatroomReference: _chatroom.selfReference);
    _nextListener.listen((List<DocumentSnapshot> snapshots) {
      List<FirechatMessage> messages = snapshots
          .map((DocumentSnapshot snap) =>
              FirechatMessage.fromMap(snap.data, snap.reference))
          .toList();
      _listenersMessagesList[_nextListener] = messages;
      _updateSinkWithMessages();
    });
    _streams.add(_nextListener);
  }

  void dispose() async {
    await _messagesController.drain();
    _messagesController.close();
    await _chatroomController.drain();
    _chatroomController.close();
  }

  /// Gathers all the [FirechatMessage] instances from all the currently active
  /// listeners, sorts them by descending dates and feeds the
  /// [_messagesController]'s sink with the complete result.
  void _updateSinkWithMessages() {
    List<FirechatMessage> messagesToSort = [];
    _listenersMessagesList.values.forEach(
        (List<FirechatMessage> messages) => messagesToSort.addAll(messages));
    _messagesController
        .add(_orderedByDate(list: _orderedByDate(list: messagesToSort)));
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
    _streamFirstMessages();
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
