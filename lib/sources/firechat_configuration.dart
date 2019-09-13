part of firechat_kit;

class FirechatKitConfiguration {
  /// The base path in Firestore for Firechat.
  ///
  /// This path should lead to a Document if it is not empty.
  ///
  /// Default : ""
  String basePath;

  /// Indicates if the read receipts feature is enabled.
  ///
  /// If you do not plan on using this feature, make sure to deactivate it in
  /// order to reduce the number of calls to Firestore.
  ///
  /// Default : enabled
  bool readReceiptsEnabled;

  /// Indicates if the feature of user focusing a chatroom (being active on it)
  /// if enabled.
  ///
  /// If you do not plan on using this feature, make sure to deactivate it in
  /// order to reduce the number of calls to Firestore.
  ///
  /// Default : enabled
  bool focusingUserEnabled;

  /// Indicates if the feature of typing tracking should be enabled.
  ///
  /// If you do not plan on using this feature, make sure to deactivate it in
  /// order to reduce the number of calls to Firestore.
  ///
  /// Default : enabled
  bool typingIndicatorEnabled;

  /// Indicates if the current user should be automatically marked as having
  /// read the most recent messages of a chatroom when they are focusing it.
  ///
  /// If false, you will have to call [FirechatConversation.markMessagesAsRead].
  ///
  /// Default : true
  bool automaticallyReadMessages;

  /// Indicates if the current user should be included or not in the list of
  /// users focusing a given chatroom, which is given when using a
  /// [FirechatConversation].
  ///
  /// Default : false
  bool countCurrentUserInFocusList;

  FirechatKitConfiguration(
      {this.basePath = "",
      this.focusingUserEnabled = true,
      this.readReceiptsEnabled = true,
      this.typingIndicatorEnabled = true,
      this.automaticallyReadMessages = true,
      this.countCurrentUserInFocusList = false})
      : assert(basePath.split("/").length % 2 == 0);

  FirechatKitConfiguration.defaultConfiguration() {
    this.basePath = "";
    this.automaticallyReadMessages = true;
    this.countCurrentUserInFocusList = false;
    this.focusingUserEnabled = true;
    this.readReceiptsEnabled = true;
    this.typingIndicatorEnabled = true;
  }
}
