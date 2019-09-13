part of firechat_kit;

class FirechatUserKeys {
  static final String kUserId = "userId";
  static final String kFirebaseUserId = "accountId";
  static final String kAvatarUrl = "avatarUrl";
  static final String kDisplayName = "displayName";
  static final String kEmail = "email";
  static final String kPhoneNumber = "phoneNumber";
  static final String kDetails = "details";
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
  /// You can provide it using the method [FirechatCurrentUser.set] in order for this
  /// data to be available directly while using FirechatKit.
  ///
  /// While not provided, the value is null.
  String avatarUrl;

  /// The display name of the user.
  ///
  /// You can provide it using the method [FirechatCurrentUser.set] in order for this
  /// data to be available directly while using FirechatKit.
  ///
  /// While not provided, the value is null.
  String displayName;

  /// The email of the user.
  ///
  /// You can provide it using the method [FirechatCurrentUser.set] in order for this
  /// data to be available directly while using FirechatKit.
  ///
  /// While not provided, the value is null.
  String email;

  /// The phone number of the user.
  ///
  /// You can provide it using the method [FirechatCurrentUser.set] in order for this
  /// data to be available directly while using FirechatKit.
  ///
  /// While not provided, the value is null.
  String phoneNumber;

  /// [Map] for custom details than can de added to the [FirechatUser].
  ///
  /// These optional data are not handled by Firechat and is provided so you can
  /// link custom data to the chatroom directly in Firestore.
  ///
  /// You can provide it using the method [FirechatCurrentUser.set] in order for this
  /// data to be available directly while using FirechatKit.
  ///
  /// While not provided, the value is null.
  Map<String, dynamic> details;

  FirechatUser(
      {this.userId,
      this.firebaseUserId,
      this.selfReference,
      this.avatarUrl,
      this.displayName,
      this.details,
      this.email,
      this.phoneNumber});

  FirechatUser.fromMap(Map<String, dynamic> map, DocumentReference reference) {
    this.selfReference = reference;
    this.userId = map[FirechatUserKeys.kUserId];
    this.firebaseUserId = map[FirechatUserKeys.kFirebaseUserId];
    this.avatarUrl = map[FirechatUserKeys.kAvatarUrl];
    this.displayName = map[FirechatUserKeys.kDisplayName];
    this.email = map[FirechatUserKeys.kEmail];
    this.phoneNumber = map[FirechatUserKeys.kPhoneNumber];
    this.details = map[FirechatUserKeys.kDetails];
  }

//  FirechatUser.fromLocalStorage(Map<String, dynamic> map) {
//    this.selfReference = Firestore.instance.document(map["path"]);
//    this.userId = map[FirechatUserKeys.kUserId];
//    this.firebaseUserId = map[FirechatUserKeys.kFirebaseUserId];
//    this.avatarUrl = map[FirechatUserKeys.kAvatarUrl];
//    this.displayName = map[FirechatUserKeys.kDisplayName];
//  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      FirechatUserKeys.kAvatarUrl: this.avatarUrl,
      FirechatUserKeys.kUserId: this.userId,
      FirechatUserKeys.kFirebaseUserId: this.firebaseUserId,
      FirechatUserKeys.kDisplayName: this.displayName,
      FirechatUserKeys.kEmail: this.email,
      FirechatUserKeys.kPhoneNumber: this.phoneNumber,
      FirechatUserKeys.kDetails: this.details
    };
    return map;
  }

//  Map<String, dynamic> toLocalStorage() {
//    Map<String, dynamic> map = {
//      "path": this.selfReference.path,
//      FirechatUserKeys.kAvatarUrl: this.avatarUrl,
//      FirechatUserKeys.kUserId: this.userId,
//      FirechatUserKeys.kFirebaseUserId: this.firebaseUserId,
//      FirechatUserKeys.kDisplayName: this.displayName
//    };
//    return map;
//  }
}
