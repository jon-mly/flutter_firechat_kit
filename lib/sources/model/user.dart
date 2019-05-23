part of firechat_kit;

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
    this.userId = map["userId"];
    this.firebaseUserId = map["accountId"];
    this.avatarUrl = map["avatarUrl"];
    this.displayName = map["displayName"];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "avatarUrl": this.avatarUrl,
      "userId": this.userId,
      "accountId": this.firebaseUserId,
      "avatarUrl": this.avatarUrl,
      "displayName": this.displayName
    };
    return map;
  }
}
