part of firechat_kit;

class FirestoreMessageInterface {
  static final String _messagesCollectionName = "messages";
  static final int _defaultListenerSize = 20;
  static DocumentSnapshot nextStartBound;

  String get _messagesPath =>
      FirechatKit.instance.configuration.basePath + _messagesCollectionName;

  //
  // ######### PAGINATED MESSAGES STREAMS
  //

  /// Returns the [Stream] of the most recent [FirechatMessage]s belonging to
  /// the [FirechatChatroom] designated by the given [chatroomReference].
  ///
  /// This [Stream] will listen for the last [minimumSize] messages, and also
  /// for the next ones to come.
  ///
  /// If an error occurs, or if [chatroomReference] is null, a [FirechatError]
  /// is thrown.
  Future<Stream<List<DocumentSnapshot>>> streamForRecentAndFutureMessagesIn(
      {@required DocumentReference chatroomReference, int minimumSize}) async {
    if (chatroomReference == null)
      throw FirechatError.kNullDocumentReferenceError;

    if (minimumSize == null) minimumSize = _defaultListenerSize;

    // To create the [Stream] that will listen for the most recent items
    // and for the next ones, we first perform a first simple query to
    // get the last message of this query.
    return await chatroomReference
        .collection(_messagesPath)
        .orderBy(FirechatMessageKeys.kDate, descending: true)
        .limit(minimumSize)
        .getDocuments()
        .then((QuerySnapshot snap) => snap.documents)
        .then((List<DocumentSnapshot> documents) {
      // Once the first x messages are found, the last one is registered
      // as the start bound of the stream that will be returned.
      if (documents.length >= 1)
        nextStartBound = documents[documents.length - 1];
      else
        nextStartBound = null;

      // Then the Stream is created, and will listen for the messages
      // newer than the one identified as [nextStartBound], and will also
      // listen for the next ones to come since it has no size limit.
      Stream<List<DocumentSnapshot>> stream = chatroomReference
          .collection(_messagesPath)
          .orderBy(FirechatMessageKeys.kDate, descending: true)
          .endAt([nextStartBound?.data[FirechatMessageKeys.kDate]])
          .snapshots()
          .map((QuerySnapshot query) => query.documents);
      // If the count of documents is lower than the size limit, this
      // means that they are no messages older than the ones the next Stream
      // will be listening to. Thus, the bound is set to null to indicate that
      // there is no older message to listen to.
      if (documents.length < minimumSize) nextStartBound = null;

      return stream;
    });
  }

  /// Returns the [Stream] of older [FirechatMessage]s belonging to the
  /// [FirechatChatroom] designated by the given [chatroomReference]. These
  /// are the ones sent before the ones listened by the main [Stream] that has
  /// been set up using [streamForRecentAndFutureMessagesIn]. This [Stream]
  /// will listen for a maximum of [sizeLimit] messages.
  ///
  /// If there are no older messages than the ones already listened to
  /// by previous listeners, null will be returned.
  /// This is indicated when [nextStartBound] is null.
  ///
  /// If [streamForOlderMessages] is called before
  /// [streamForRecentAndFutureMessagesIn], the latter will be called instead.
  /// But make sure that the first one is called
  /// before anything to avoid any weird behavior.
  ///
  /// If an error occurs, or if [chatroomReference] is null, a [FirechatError]
  /// is thrown.
  Future<Stream<List<DocumentSnapshot>>> streamForOlderMessages(
      {@required DocumentReference chatroomReference, int sizeLimit}) async {
    if (chatroomReference == null)
      throw FirechatError.kNullDocumentReferenceError;

    if (nextStartBound == null) return null;

    if (sizeLimit == null) sizeLimit = _defaultListenerSize;

    // To create the [Stream] that will listen for a defined array of items, we
    // first perform a first simple query to get the last message of this query.
    return await chatroomReference
        .collection(_messagesPath)
        .orderBy(FirechatMessageKeys.kDate, descending: true)
        .startAt([nextStartBound.data[FirechatMessageKeys.kDate]])
        .limit(sizeLimit)
        .getDocuments()
        .then((QuerySnapshot snap) => snap.documents)
        .then((List<DocumentSnapshot> documents) {
          // Once the first x messages after the start bound are found, the last one
          // is registered as the start bound of the stream that will be returned.
          if (documents.length < 1) return null;
          DocumentSnapshot end = documents[documents.length - 1];

          // Then the Stream is created, and will listen for the messages
          // older than the one identified as [nextStartBound].
          Stream<List<DocumentSnapshot>> stream = chatroomReference
              .collection(_messagesPath)
              .orderBy(FirechatMessageKeys.kDate, descending: true)
              .startAfter([nextStartBound.data[FirechatMessageKeys.kDate]])
              .endAt([end.data[FirechatMessageKeys.kDate]])
              .snapshots()
              .map((QuerySnapshot query) => query.documents);
          // If the count of documents is lower than the size limit, this
          // means that they are no messages older than the ones the next Stream
          // will be listening to. Thus, the bound is set to null to indicate that
          // there is no older message to listen to.
          if (documents.length < sizeLimit) nextStartBound = null;

          nextStartBound = end;

          return stream;
        });
  }

  //
  // ######## SINGLE MESSAGE FETCH
  //

  /// Fetches and return the [FirechatMessage] related to the given [reference].
  ///
  /// If an error occurs or if the [reference] is null, a [FirechatError] is
  /// thrown.
  Future<FirechatMessage> messageFor(
      {@required DocumentReference reference}) async {
    if (reference == null) throw FirechatError.kNullDocumentReferenceError;
    return await reference.get().then((DocumentSnapshot snap) {
      if (snap == null || !snap.exists)
        throw FirechatError.kMessageNotFoundError;
      return FirechatMessage.fromMap(snap.data, snap.reference);
    }).catchError((e) {
      print(e);
      if (e is FirechatError) throw e;
      throw FirechatError.kMessageFetchError;
    });
  }

  //
  // ######## PUBLICATION & DELETION
  //

  /// Publish the [message] on Firestore (this only adds the document to the
  /// list of all sent messages).
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<FirechatMessage> send(FirechatMessage message) async {
    if (message.selfReference == null)
      message.selfReference =
          message.chatroomRef.collection(_messagesPath).document();
    await Firestore.instance
        .runTransaction((_) => message.selfReference.setData(message.toMap()))
        .catchError((e) {
      print(e);
      throw FirechatError.kMessageSendingError;
    });
    return message;
  }

  /// Deletes the given [message]-related document in Firestore.
  ///
  /// Note that all references to this message should be removed as well.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> delete(FirechatMessage message) async {
    if (message.selfReference == null)
      throw FirechatError.kMessageNotFoundError;
    await message.selfReference.delete().catchError((e) {
      print(e);
      throw FirechatError.kMessageDeletionError;
    });
  }
}
