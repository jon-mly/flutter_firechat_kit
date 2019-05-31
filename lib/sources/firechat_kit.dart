part of firechat_kit;

class FirechatKit {
  static final FirechatKit instance = FirechatKit();

  static const MethodChannel _channel = const MethodChannel('firechat_kit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  bool _isConfigured = false;

  FirechatKitConfiguration _configuration;
  FirechatKitConfiguration get configuration => _configuration;

  FirechatCurrentUser _currentUser;
  FirechatCurrentUser get currentUser => _currentUser;

  FirechatChatrooms _chatrooms;
  FirechatChatrooms get chatrooms => _chatrooms;

  FirechatConversation _focusedConversation;
  FirechatConversation get conversation => _focusedConversation;

  /// Configures [FirechatKit] to conforms to your configuration.
  ///
  /// This should be called when the app is launched.
  void configure({FirechatKitConfiguration configuration}) {
    if (configuration == null)
      _configuration = FirechatKitConfiguration.defaultConfiguration();
    else
      _configuration = configuration;
    _isConfigured = true;
  }

  void dispose() {
    _currentUser.dispose();
    _currentUser = null;
    _chatrooms.dispose();
    _chatrooms = null;
  }

  //
  // ########## AUTHENTICATION
  //

  /// Logs in anonymously using Firebase Auth, and links the user to the data
  /// related to the account designated by [userId].
  ///
  /// [login] should be called right after the user is logged into your
  /// application.
  ///
  /// This [userId] is the ID of the user in your database.
  /// See also [FirechatUser.userId].
  ///
  /// If an error occurs, this throws a [FirechatError].
  Future<FirechatCurrentUser> login({@required String userId}) async {
    // Login
    String firebaseUserId =
        await AuthInterface.instance.login().catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kLoggingInError;
    });
    if (firebaseUserId == null) throw FirechatError.kLoggingInError;

    // Get the DocumentSnapshot of the Current user
    DocumentSnapshot currentUserSnap = await FirestoreUserInterface()
        .userDocumentSnapshotByUserId(userId: userId)
        .catchError((e) {
      if (e is FirechatError) throw e;
      throw FirechatError.kFirestoreUserFetchError;
    });

    // Create the current instance of the related FirechatUser if the previous
    // instruction has not returned any result.
    FirechatUser user;
    if (currentUserSnap == null) {
      user = await FirestoreUserInterface()
          .uploadFirechatUser(
              FirechatUser(userId: userId, firebaseUserId: firebaseUserId))
          .catchError((e) {
        if (e is FirechatError) throw e;
        throw FirechatError.kFirestoreUserUploadError;
      });
    } else
      // Otherwise, the firebaseUserId is updated to Firestore.
      user = await FirestoreUserInterface().updateFirebaseIdOf(
          FirechatUser.fromMap(currentUserSnap.data, currentUserSnap.reference),
          firebaseUserId);

    // Configure the Current User based on the initial instance.
    _currentUser = FirechatCurrentUser(user: user);

    return currentUser;
  }

  /// Logs out the Firebase Auth user.
  ///
  /// [logout] should be called right after the user is logged out of your
  /// application.
  ///
  /// If an error occurs, this throws a [FirechatError].
  void logout() {
    dispose();
  }

  //
  // ########## CHATROOMS
  //

  /// Prepares the [FirechatChatrooms] object that will be useful for the
  /// whole app's lifecycle.
  ///
  /// This step required the user to be logged in. If this is called before
  /// [login], a [FirechatError] will be thrown.
  ///
  /// Also, note that this step is only supposed to be done once. While it has
  /// no impact expect more queries with Firestore, this may indicate that
  /// your app is calling this more than it should.
  ///
  /// Generally, if an error occurs, this will throw a [FirechatError].
  FirechatChatrooms prepareChatrooms() {
    if (chatrooms != null)
      print(
          "FirechatKit.prepareChatrooms() has been unnecessarily called, while it was already prepared. Although it has no impact in itself, it may indicate that your app is calling this more than it should.");
    if (currentUser == null) throw FirechatError.kNotLoggedInError;
    _chatrooms = FirechatChatrooms(
        userDocumentReference: _currentUser.user.selfReference);
    return _chatrooms;
  }

  //
  // ########## CONVERSATION
  //

  /// Prepares the [FirechatConversation] related to the given [chatroom].
  ///
  /// This instance contains the [Stream] for all the [FirechatMessage]s, and the
  /// methods to send and delete a [FirechatMessage].
  ///
  /// This instance will be stored in [conversation], and will not be replaced
  /// until you call this method again. That way, the streams remain active
  /// as long as the conversation is more or less focused.
  ///
  /// Generally, if an error occurs, this will throw a [FirechatError].
  FirechatConversation getConversationFor(
      {@required FirechatChatroom chatroom}) {
    if (chatroom == null) throw FirechatError.kNullChatroomError;
    // If the conversation was already focused, there is no need to instantiate
    // it again.
    if (_focusedConversation != null &&
        _focusedConversation.chatroomReference == chatroom.selfReference)
      return _focusedConversation;
    // Otherwise, the data are gathered to build the conversation.
    _focusedConversation = FirechatConversation.streamed(
        chatroom: chatroom, currentUserRef: currentUser.user.selfReference);
    return _focusedConversation;
  }

  /// Prepares the [FirebaseConversation] for the private conversation
  /// with the user designated by the [id], which is the ID in your database.
  ///
  /// This instance contains the [Stream] for all the [FirechatMessage]s, and the
  /// methods to send and delete a [FirechatMessage].
  ///
  /// This instance will be stored in [conversation], and will not be replaced
  /// until you call this method again. That way, the streams remain active
  /// as long as the conversation is more or less focused.
  ///
  /// Note that if no message has been sent with the other user, the
  /// [FirechatChatroom] exists only locally, until the first message is
  /// sent.
  ///
  /// Generally, if an error occurs, this will throw a [FirechatError].
  Future<FirechatConversation> getConversationWithUser(
      {@required String id}) async {
    if (id == null) throw FirechatError.kNullUserId;
    DocumentReference contactRef = await FirestoreUserInterface()
        .userDocumentReferenceByUserId(userId: id);
    if (contactRef == null) throw FirechatError.kNoUserFoundFromId;
    // Otherwise, the data are gathered to build the conversation.
    _focusedConversation =
        await _chatrooms.getConversationWithUser(contactRef: contactRef);
    return _focusedConversation;
  }

  //
  // ########## HELPERS
  //

  /// Indicates if the given [message] has been sent by the current user or
  /// by someone else.
  bool authorIsCurrentUserFor({@required FirechatMessage message}) {
    return message.authorRef == _currentUser.user.selfReference;
  }
}
