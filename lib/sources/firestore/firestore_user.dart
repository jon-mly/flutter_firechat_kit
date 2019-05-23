part of firechat_kit;

class FirestoreUserInterface {
  static final String _usersCollectionName = "users";

  /// Fetches and returns the snapshot of the FirechatUser designated by
  /// the given [firebaseUserId].
  ///
  /// If [firebaseUserId] is null or if it has no match with an existing
  /// instance, null is returned.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  static Future<DocumentSnapshot> userDocumentRefByFirebaseId(
      {@required String firebaseUserId}) async {
    if (firebaseUserId == null || firebaseUserId.isEmpty) return null;
    // TODO: make the path to be flexible / configured.
    return await Firestore.instance
        .collection(_usersCollectionName)
        .where("firebaseUserId", isEqualTo: firebaseUserId)
        .getDocuments()
        .then((QuerySnapshot snap) {
      if (snap.documents.isEmpty) return null;
      return snap.documents.first;
    }).catchError((e) {
      print(e);
      throw FirechatError.kFirestoreUserFetchError;
    });
  }

  /// Returns the [DocumentSnapshot] of the given [ref].
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  static Future<DocumentSnapshot> userFromReference(
      {@required DocumentReference ref}) async {
    return ref.get().catchError((e) {
      print(e);
      throw FirechatError.kFirestoreUserFetchError;
    });
  }

  /// Fetches and returns the snapshot of the FirechatUser designated by
  /// the given [userId], which is the ID of the user in your database.
  ///
  /// This method is especially made to be used when fetching the profile of the
  /// current user who just logged in.
  ///
  /// If [userId] is null or if it has no match with an existing
  /// instance, null is returned.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  static Future<DocumentSnapshot> userDocumentSnapshotByUserId(
      {@required String userId}) async {
    if (userId == null || userId.isEmpty) return null;
    // TODO: make the path to be flexible / configured.
    return await Firestore.instance
        .collection(_usersCollectionName)
        .where("userId", isEqualTo: userId)
        .getDocuments()
        .then((QuerySnapshot snap) {
      if (snap.documents.isEmpty) return null;
      return snap.documents.first;
    }).catchError((e) {
      print(e);
      throw FirechatError.kFirestoreUserFetchError;
    });
  }

  /// Fetches and returns the [DocumentReference] of the FirechatUser designated by
  /// the given [userId], which is the ID of the user in your database.
  ///
  /// If [userId] is null or if it has no match with an existing
  /// instance, null is returned.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  static Future<DocumentReference> userDocumentReferenceByUserId(
      {@required String userId}) async {
    return await userDocumentSnapshotByUserId(userId: userId)
        .then((DocumentSnapshot snap) => snap.reference)
        .catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kNoUserFoundFromId;
    });
  }

  /// Uploads the [user] to the database by replacing the existing instance
  /// based on [FirechatUser.selfReference] or adds a new instance if
  /// [FirechatUser.selfReference] is null or does not lead to any existing
  /// instance.
  ///
  /// [user] is returned at the end of the function, so as to if the
  /// [selfReference] has been modified, it can be saved locally.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  static Future<FirechatUser> uploadFirechatUser(FirechatUser user) async {
    if (user.selfReference == null)
      // TODO: make the path to be flexible / configured.
      user.selfReference =
          Firestore.instance.collection(_usersCollectionName).document();
    await user.selfReference.setData(user.toMap()).catchError((e) {
      print(e);
      throw FirechatError.kFirestoreUserUploadError;
    });
    return user;
  }

  /// Replaces the [firebaseUserId] field of the document related to the given
  /// [user] by the [newId].
  ///
  /// [user] is returned at the end of the function, so as to the modification
  /// can be retrieved without additional code.
  ///
  /// This is especially used when the user logs in. Since the [firebaseUserId]
  /// might have changed, it is to be replaced.
  ///
  /// If an error occurs, a [FirechatError] is thrown.
  static Future<FirechatUser> updateFirebaseIdOf(
      FirechatUser user, String newId) async {
    user.firebaseUserId = newId;
    await user.selfReference
        .updateData({"firebaseUserId": newId}).catchError((e) {
      print(e);
      throw FirechatError.kFirestoreUserUpdateError;
    });
    return user;
  }
}
