part of firechat_kit;

class FirestoreChatroomInterface {
  static final String _chatroomsCollectionName = "chatrooms";
  static final int _defaultListenerSize = 20;
  static DocumentSnapshot nextStartBound;

  String get _chatroomsPath =>
      FirechatKit.instance.configuration.basePath + _chatroomsCollectionName;

  //
  // ########## CHATROOMS PAGINATED STREAMS
  //

  /// Returns the [Stream] for the most recent [FirechatChatroom]s where the
  /// user related to the given [userReference] takes part.
  ///
  /// This [Stream] will listen for the last [minimumSize] messages, and also
  /// for the next ones to be updated (thus being more recent).
  ///
  /// If an error occurs, or if [userReference] is null, a [FirechatError]
  /// is thrown.
  Future<Stream<List<DocumentSnapshot>>> streamForRecentAndFutureChatroomsFor(
      {@required DocumentReference userReference, int minimumSize}) async {
    if (userReference == null) throw FirechatError.kNullDocumentReferenceError;

    if (minimumSize == null) minimumSize = _defaultListenerSize;

    // To create the [Stream] that will listen for the most recent items
    // and for the next ones, we first perform a first simple query to
    // get the last message of this query.
    return await Firestore.instance
        .collection(_chatroomsPath)
        .orderBy(FirechatChatroomKeys.kLastMessageDate, descending: true)
        .where(FirechatChatroomKeys.kPeopleRef, arrayContains: userReference)
        .limit(minimumSize)
        .getDocuments()
        .then((QuerySnapshot snap) => snap.documents)
        .then((List<DocumentSnapshot> documents) {
      Stream<List<DocumentSnapshot>> stream;

      // Once the first x chatrooms are found, the last one is registered
      // as the start bound of the stream that will be returned.
      //
      // If there is no bound to limit the [Stream], the returned stream will
      // instead listen for all the chatrooms to which the user takes part to.
      if (documents.length >= 1) {
        nextStartBound = documents[documents.length - 1];
        // Then the Stream is created, and will listen for the chatrooms
        // newer than the one identified as [nextStartBound], and will also
        // listen for the next ones to be updated since it has no size limit.
        stream = Firestore.instance
            .collection(_chatroomsPath)
            .orderBy(FirechatChatroomKeys.kLastMessageDate, descending: true)
            .where(FirechatChatroomKeys.kPeopleRef,
                arrayContains: userReference)
            .endAt([nextStartBound.data[FirechatChatroomKeys.kLastMessageDate]])
            .snapshots()
            .map((QuerySnapshot query) => query.documents);
      } else {
        // Then the Stream is created, and will listen for all the chatrooms,
        // and will also listen for the next ones to be updated since it has no
        // size limit.
        stream = Firestore.instance
            .collection(_chatroomsPath)
            .orderBy(FirechatChatroomKeys.kLastMessageDate, descending: true)
            .where(FirechatChatroomKeys.kPeopleRef,
                arrayContains: userReference)
            .snapshots()
            .map((QuerySnapshot query) => query.documents);
      }

      // If the count of documents is lower than the size limit, this
      // means that they are no messages older than the ones the next Stream
      // will be listening to. Thus, the bound is set to null to indicate that
      // there is no older message to listen to.
      if (documents.length < minimumSize) nextStartBound = null;

      return stream;
    });
  }

  /// Returns the [Stream] for older [FirechatChatroom]s where the
  /// user related to the given [userReference] takes part. These
  /// are the ones updated before the ones listened by the main [Stream] that has
  /// been set up using [streamForRecentAndFutureChatroomsFor]. This [Stream]
  /// will listen for a maximum of [sizeLimit] messages.
  ///
  /// This [Stream] will listen for the last [minimumSize] messages, and also
  /// for the next ones to be opened.
  ///
  /// If an error occurs, or if [userReference] is null, a [FirechatError]
  /// is thrown.
  Future<Stream<List<DocumentSnapshot>>> streamOlderChatroomsFor(
      {@required DocumentReference userReference, int sizeLimit}) async {
    if (userReference == null) throw FirechatError.kNullDocumentReferenceError;

    if (sizeLimit == null) sizeLimit = _defaultListenerSize;

    // To create the [Stream] that will listen for the most recent items
    // and for the next ones, we first perform a first simple query to
    // get the last message of this query.
    return await Firestore.instance
        .collection(_chatroomsPath)
        .orderBy(FirechatChatroomKeys.kLastMessageDate, descending: true)
        .where(FirechatChatroomKeys.kPeopleRef, arrayContains: userReference)
        .startAt([nextStartBound.data[FirechatChatroomKeys.kLastMessageDate]])
        .limit(sizeLimit)
        .getDocuments()
        .then((QuerySnapshot snap) => snap.documents)
        .then((List<DocumentSnapshot> documents) {
          // Once the first x chatrooms are found, the last one is registered
          // as the start bound of the stream that will be returned.
          if (documents.length < 1) return null;
          DocumentSnapshot end = documents[documents.length - 1];

          // Then the Stream is created, and will listen for the chatrooms
          // older than the one identified as [nextStartBound].
          Stream<List<DocumentSnapshot>> stream = Firestore.instance
              .collection(_chatroomsPath)
              .orderBy(FirechatChatroomKeys.kLastMessageDate, descending: true)
              .where(FirechatChatroomKeys.kPeopleRef,
                  arrayContains: userReference)
              .startAfter([end.data[FirechatChatroomKeys.kLastMessageDate]])
              .endAt(
                  [nextStartBound.data[FirechatChatroomKeys.kLastMessageDate]])
              .snapshots()
              .map((QuerySnapshot query) => query.documents);
          // If the count of documents is lower than the size limit, this
          // means that they are no messages older than the ones the next Stream
          // will be listening to. Thus, the bound is set to null to indicate that
          // there is no older message to listen to.
          if (documents.length < sizeLimit) nextStartBound = null;

          return stream;
        });
  }

  //
  // ######### SINGLE CHATROOM STREAM
  //

  /// Returns the [Stream] of the document related to the [FirechatChatroom]
  /// designated by [chatroomRef].
  Stream<DocumentSnapshot> chatroomStreamFor(
      {@required DocumentReference chatroomRef}) {
    return chatroomRef.snapshots();
  }

  /// Searches for an existing private [FirechatChatrooms] between the two users
  /// designated by their [DocumentReference].
  ///
  /// If none is found, null is returned.
  ///
  /// Can throw an [FirechatError] if an error occurs.
  ///
  /// Since the Firestore Query system does not support compound queries using
  /// multiple [arrayContains] queries, the [FirechatChatroom] is fetched in two
  /// steps :
  /// all the private chatrooms of the current user are fetched, and the
  /// filtration to find the correct one is done locally.
  Future<FirechatChatroom> privateChatroomBetween(
      {@required DocumentReference firstUserRef,
      @required DocumentReference secondUserRef}) async {
    // Gets conversations where the first user takes part.
    // TODO: make the path to be flexible / configured.
    List<FirechatChatroom> candidates = await Firestore.instance
        .collection(_chatroomsPath)
        .where(FirechatChatroomKeys.kChatroomTypeIndex,
            isEqualTo: FirechatChatroomType.oneToOne.index)
        .where(FirechatChatroomKeys.kPeopleRef, arrayContains: firstUserRef)
        .getDocuments()
        .then((QuerySnapshot snap) => snap.documents
            .map((DocumentSnapshot snap) =>
                FirechatChatroom.fromMap(snap.data, snap.reference))
            .toList())
        .catchError((e) {
      print(e);
      throw FirechatError.kFirestoreChatroomQueryError;
    });
    if (candidates == null || candidates.isEmpty) return null;
    // Filters locally the conversations to get the first one where the second
    // user takes also part.
    return candidates.firstWhere(
        (FirechatChatroom conversation) =>
            conversation.peopleRef.contains(secondUserRef),
        orElse: () => null);
  }

  //
  // ########## UPLOAD
  //

  /// Publish the [chatroom] on Firestore.
  ///
  /// If the [chatroom.selfReference] is empty, a value will be set.
  /// Hence, it is returned once the operation is complete so you can proceed
  /// with the defined reference.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<FirechatChatroom> exportToFirestore(
      {@required FirechatChatroom chatroom}) async {
    // TODO: make the path to be flexible / configured.
    if (chatroom.selfReference == null)
      chatroom.selfReference =
          Firestore.instance.collection(_chatroomsPath).document();
    await Firestore.instance
        .runTransaction((_) => chatroom.selfReference.setData(chatroom.toMap()))
        .catchError((e) {
      print(e);
      throw FirechatError.kFirestoreChatroomUploadError;
    });
    return chatroom;
  }

  /// Uploads the [chatroom.details] to Firestore.
  ///
  /// This required [chatroom.details] to be set.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> updateChatroomDetails(
      {@required FirechatChatroom chatroom}) async {
    if (chatroom.selfReference == null)
      throw FirechatError.kNullDocumentReferenceError;

    await Firestore.instance
        .runTransaction((_) => chatroom.selfReference
            .updateData({FirechatChatroomKeys.kDetails: chatroom.details}))
        .catchError((e) {
      print(e);
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }

  //
  // ########## COMPOSING
  //

  /// Updates the `composingPeopleRef` of the document related to the [chatroom]
  /// with the [userReference] added or removed accordingly to [isComposing].
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> setUserIsComposing(
      {@required FirechatChatroom chatroom,
      @required DocumentReference userReference,
      @required bool isComposing}) async {
    if (chatroom.selfReference == null)
      throw FirechatError.kNullDocumentReferenceError;
    if (chatroom.composingPeopleRef == null) chatroom.composingPeopleRef = [];

    if (isComposing && !chatroom.composingPeopleRef.contains(userReference))
      chatroom.composingPeopleRef =
          List<DocumentReference>.from(chatroom.composingPeopleRef)
            ..add(userReference);
    else if (!isComposing & chatroom.composingPeopleRef.contains(userReference))
      chatroom.composingPeopleRef =
          List<DocumentReference>.from(chatroom.composingPeopleRef)
            ..remove(userReference);

    await Firestore.instance
        .runTransaction((_) => chatroom.selfReference.updateData({
              FirechatChatroomKeys.kComposingPeopleRef:
                  chatroom.composingPeopleRef
            }))
        .catchError((e) {
      print(e);
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }

  //
  // ########## FOCUSING
  //

  /// Updates the `focusingPeopleRef` of the document related to the [chatroom]
  /// with the [userReference] added or removed accordingly to [isFocusing].
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> setUserFocusing(
      {@required FirechatChatroom chatroom,
      @required DocumentReference userReference,
      @required bool isFocusing}) async {
    if (chatroom.selfReference == null)
      throw FirechatError.kNullDocumentReferenceError;
    if (chatroom.focusingPeopleRef == null) chatroom.focusingPeopleRef = [];

    if (isFocusing && !chatroom.focusingPeopleRef.contains(userReference))
      chatroom.focusingPeopleRef =
          List<DocumentReference>.from(chatroom.focusingPeopleRef)
            ..add(userReference);
    else if (!isFocusing & chatroom.focusingPeopleRef.contains(userReference))
      chatroom.focusingPeopleRef =
          List<DocumentReference>.from(chatroom.focusingPeopleRef)
            ..remove(userReference);

    await Firestore.instance
        .runTransaction((_) => chatroom.selfReference.updateData({
              FirechatChatroomKeys.kFocusingPeopleRef:
                  chatroom.focusingPeopleRef
            }))
        .catchError((e) {
      print(e);
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }

  //
  // ######## MESSAGE SENT UPDATE
  //

  /// Updates the [FirechatChatroom] of the given [chatroom] with the last
  /// message data and uploads the modified field to Firestore.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> updateLastMessageFor(
      {@required FirechatChatroom chatroom,
      @required FirechatMessage message}) async {
    if (chatroom.selfReference == null)
      throw FirechatError.kNullDocumentReferenceError;

    await Firestore.instance
        .runTransaction((_) => chatroom.selfReference.updateData({
              FirechatChatroomKeys.kLastMessageDate:
                  message.date.millisecondsSinceEpoch,
              FirechatChatroomKeys.kLastMessageRef: message.selfReference
            }))
        .catchError((e) {
      print(e);
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }

  //
  // ######## LAST MESSAGE READ FOR EACH USER
  //

  /// Updates the [chatroom.lastMessagesRead] entry for the given user related
  /// to the given [userRef] to reflect that the last message they read is
  /// the given [message].
  ///
  /// The modified [chatroom] is then uploaded to Firestore.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  Future<void> setLastReadMessageForUser(
      {@required DocumentReference userRef,
      @required FirechatChatroom chatroom,
      @required FirechatMessage message}) async {
    if (userRef == null) throw FirechatError.kNullDocumentReferenceError;
    if (message.selfReference == null)
      throw FirechatError.kNullDocumentReferenceError;
    if (chatroom.selfReference == null)
      throw FirechatError.kNullDocumentReferenceError;

    chatroom.lastMessagesRead[userRef] = message.selfReference;

    await Firestore.instance
        .runTransaction((_) => chatroom.selfReference.updateData(chatroom
            .entryReadBy(userRef: userRef, messageRef: message.selfReference)))
        .catchError((e) {
      print(e);
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }
}
