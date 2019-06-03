part of firechat_kit;

class LocalStorageMessage {
  static final String _messagesTableName = "Message";

  static Future<void> createUsersTableIn(Database db) async {
    await db.execute("CREATE TABLE $_messagesTableName ("
        "id integer primary key AUTOINCREMENT,"
        "${FirechatMessageKeys.kAuthorRef} TEXT,"
        "${FirechatMessageKeys.kDate} TEXT,"
        "${FirechatUserKeys.kAvatarUrl} TEXT,"
        "${FirechatUserKeys.kDisplayName} TEXT,"
        ")");
  }
}
