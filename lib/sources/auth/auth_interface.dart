part of firechat_kit;

class AuthInterface {
  static final AuthInterface instance = AuthInterface();

  /// Logs in anonymously, and return the ID of the [FirebaseUser].
  ///
  /// If an error occurs, a [FirechatError] is returned.
  ///
  /// Note that since the process of login is anonymous, the resulting
  /// [FirebaseUser] is not to be retained permanently, and thus should
  /// not be used to store any value.
  ///
  /// Instead, do use the fields of [FirechatUser].
  Future<String> login() async {
    return await FirebaseAuth.instance
        .signInAnonymously()
        .then((FirebaseUser user) => user.uid)
        .catchError((e) => throw FirechatError.kLoggingInError);
  }

  /// Logs out the [FirebaseUser].
  void logout() {
    FirebaseAuth.instance.signOut();
  }
}
