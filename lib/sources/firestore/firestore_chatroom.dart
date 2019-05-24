part of firechat_kit;

class FirestoreChatroomInterface {
  static final String _chatroomsCollectionName = "chatrooms";

  //
  // ########## STREAMS
  //

  /// Fetches and returns the [Stream] of all the [DocumentSnapshot] for
  /// [FirechatChatroom]s in which the user takes part.
  ///
  /// The query is based on the [DocumentReference] of the document related
  /// to the [FirechatUser] instance of the user. That way, the data is still
  /// available, even if you change the [FirechatUser.userId].
  ///
  /// If an error occurs, a [FirechatError] is returned.
  static Stream<List<DocumentSnapshot>> chatroomsForUser(
      {@required DocumentReference userReference}) {
    // TODO: make the path to be flexible / configured.
    return Firestore.instance
        .collection(_chatroomsCollectionName)
        .where('peopleRef', arrayContains: userReference)
        .snapshots()
        .map((QuerySnapshot query) => query.documents);
  }

  /// Returns the [Stream] of the document related to the [FirechatChatroom]
  /// designated by [chatroomRef].
  static Stream<DocumentSnapshot> chatroomStreamFor(
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
  static Future<FirechatChatroom> privateChatroomBetween(
      {@required DocumentReference firstUserRef,
      @required DocumentReference secondUserRef}) async {
    // Gets conversations where the first user takes part.
    // TODO: make the path to be flexible / configured.
    List<FirechatChatroom> candidates = await Firestore.instance
        .collection(_chatroomsCollectionName)
        .where("chatroomTypeIndex",
            isEqualTo: FirechatChatroomType.oneToOne.index)
        .where("peopleRef", arrayContains: firstUserRef)
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
  static Future<FirechatChatroom> exportToFirestore(
      {@required FirechatChatroom chatroom}) async {
    // TODO: make the path to be flexible / configured.
    if (chatroom.selfReference == null)
      chatroom.selfReference =
          Firestore.instance.collection(_chatroomsCollectionName).document();
    await Firestore.instance
        .runTransaction((_) => chatroom.selfReference.setData(chatroom.toMap()))
        .catchError((e) {
      print(e);
      throw FirechatError.kFirestoreChatroomUploadError;
    });
    return chatroom;
  }

  //
  // ########## COMPOSING
  //

  /// Updates the `composingPeopleRef` of the document related to the [chatroom]
  /// with the [userReference] added or removed accordingly to [isComposing].
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  static Future<void> setUserIsComposing(
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
        .runTransaction((_) => chatroom.selfReference
            .updateData({"composingPeopleRef": chatroom.composingPeopleRef}))
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
  static Future<void> setUserFocusing(
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
        .runTransaction((_) => chatroom.selfReference
            .updateData({"focusingPeopleRef": chatroom.focusingPeopleRef}))
        .catchError((e) {
      print(e);
      throw FirechatError.kFirestoreChatroomUploadError;
    });
  }
}
