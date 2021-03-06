part of firechat_kit;

class FirechatCurrentUser {
  BehaviorSubject<FirechatUser> _currentUserController =
      BehaviorSubject<FirechatUser>();

  Observable<FirechatUser> get onUserUpdate => _currentUserController.stream;

  FirechatUser _user;
  FirechatUser get user => _user;

  FirechatCurrentUser({@required FirechatUser user}) {
    _user = user;
    _currentUserController.sink.add(user);
    this._create();
  }

  void _create() {
    // Listens for changes of the instance in Firestore and fills the up
    // when a change is received.
    // TODO: should not call directly Firestore methods
    _user.selfReference.snapshots().listen((DocumentSnapshot snap) {
      if (snap.data == null || snap.data.isEmpty) return;
      FirechatUser currentUser =
          FirechatUser.fromMap(snap.data, snap.reference);
      _user = currentUser;
      _currentUserController.add(currentUser);
    });
  }

  void dispose() async {
    await _currentUserController.drain();
    _currentUserController.close();
  }

  /// Sets the given data to the [FirechatUser].
  ///
  /// The following values can be changed :
  /// - the [avatarUrl] of the user
  /// - their [displayName]
  /// - their [userId], which is to be changed with care since this is the
  /// ID of the user in your database. See also [FirechatUser.userId].
  /// - the [email] of the user
  /// - the [phoneNumber] of the user
  /// - the [details] you might want to be available directly in Firestore.
  void set(
      {String avatarUrl,
      String displayName,
      String userId,
      String email,
      String phoneNumber,
      Map<String, dynamic> details}) {
    FirechatUser mostRecentData = _user;
    if (avatarUrl != null) mostRecentData.avatarUrl = avatarUrl;
    if (displayName != null) mostRecentData.displayName = displayName;
    if (userId != null) mostRecentData.userId = userId;
    if (email != null) mostRecentData.email = email;
    if (phoneNumber != null) mostRecentData.phoneNumber = phoneNumber;
    if (details != null) mostRecentData.details = details;
    FirestoreUserInterface().uploadFirechatUser(mostRecentData);
  }
}
