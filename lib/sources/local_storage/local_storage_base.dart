part of firechat_kit;

class LocalStorageBase {
  LocalStorageBase._();

  static final LocalStorageBase instance = LocalStorageBase._();
  static final String _dbName = "firechat_kit.db";

  LocalStorageUser users;
//  LocalStorageMessage messages;
//  LocalStorageChatroom chatrooms;

  Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await getDatabase();
    return _database;
  }

  //
  // ########## LIFECYCLE
  //

  Future<Database> getDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + _dbName;
    _database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await LocalStorageUser.createUsersTableIn(db);
      // TODO: create messages table
      // TODO: create chatrooms table
    });
    users = LocalStorageUser(_database);
    return _database;
  }
}
