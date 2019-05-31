part of firechat_kit;

class FirechatKitConfiguration {
  /// The base path in Firestore for Firechat.
  ///
  /// This path should lead to a Document if it is not empty.
  ///
  /// Default : ""
  String basePath;

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
  bool countCurrentUSerInFocusList;

  FirechatKitConfiguration(
      {this.basePath = "",
      this.automaticallyReadMessages = true,
      this.countCurrentUSerInFocusList = false})
      : assert(basePath.split("/").length % 2 == 0);

  FirechatKitConfiguration.defaultConfiguration() {
    this.basePath = "";
    this.automaticallyReadMessages = true;
    this.countCurrentUSerInFocusList = false;
  }
}
