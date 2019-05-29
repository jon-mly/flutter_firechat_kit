part of firechat_kit;

class FirechatUserKeys {
  static final String kUserId = "userId";
  static final String kFirebaseUserId = "accountId";
  static final String kAvatarUrl = "avatarUrl";
  static final String kDisplayName = "displayName";
}

class FirechatUser {
  /// The ID of the used in your database to which this instance will be
  /// bound.
  String userId;

  /// The ID of the Firebase Auth account which bridges the user in your
  /// database and this instance.
  String firebaseUserId;

  /// The reference of this instance in the Firestore Database.
  DocumentReference selfReference;

  /// Ths URL of the user's avatar.
  ///
  /// You can provide it using the method [configure] in order for this
  /// data to be available directly while using FirechatKit.
  ///
  /// While not provided, the value is null.
  String avatarUrl;

  /// The display name of the user.
  ///
  /// You can provide it using the method [configure] in order for this
  /// data to be available directly while using FirechatKit.
  ///
  /// While not provided, the value is null.
  String displayName;

  FirechatUser(
      {this.userId,
      this.firebaseUserId,
      this.selfReference,
      this.avatarUrl,
      this.displayName});

  FirechatUser.fromMap(Map<String, dynamic> map, DocumentReference reference) {
    this.selfReference = reference;
    this.userId = map[FirechatUserKeys.kUserId];
    this.firebaseUserId = map[FirechatUserKeys.kFirebaseUserId];
    this.avatarUrl = map[FirechatUserKeys.kAvatarUrl];
    this.displayName = map[FirechatUserKeys.kDisplayName];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      FirechatUserKeys.kAvatarUrl: this.avatarUrl,
      FirechatUserKeys.kUserId: this.userId,
      FirechatUserKeys.kFirebaseUserId: this.firebaseUserId,
      FirechatUserKeys.kDisplayName: this.displayName
    };
    return map;
  }
}
