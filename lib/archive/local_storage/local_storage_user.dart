//part of firechat_kit;
//
//class LocalStorageUser {
//  static final String _usersTableName = "User";
//
//  Database db;
//
//  LocalStorageUser(this.db);
//
//  static Future<void> createUsersTableIn(Database db) async {
//    await db.execute("CREATE TABLE $_usersTableName ("
//        "path TEXT primary key,"
//        "${FirechatUserKeys.kUserId} TEXT,"
//        "${FirechatUserKeys.kFirebaseUserId} TEXT,"
//        "${FirechatUserKeys.kAvatarUrl} TEXT,"
//        "${FirechatUserKeys.kDisplayName} TEXT,"
//        ")");
//  }
//
//  //
//  // ########## CRUD
//  //
//
//  // Creation
//
//  Future<void> addUser(FirechatUser user) async {
//    db.insert(_usersTableName, user.toLocalStorage());
//  }
//
//  // Read
//
//  Future<List<FirechatUser>> getUsersWithReferences(
//      List<DocumentReference> references) async {
//    var response = await db.query(_usersTableName,
//        where: "path = ?",
//        whereArgs: references.map((ref) => ref.path).toList());
//    return (response != null)
//        ? response.map((map) => FirechatUser.fromLocalStorage(map)).toList()
//        : null;
//  }
//
//  // Update
//
//  Future<void> updateUser(FirechatUser user) async {
//    db.update(_usersTableName, user.toLocalStorage(),
//        where: "path = ?", whereArgs: [user.selfReference.path]);
//  }
//
//  // Deletion
//
//  Future<void> deleteUser(FirechatUser user) async {
//    db.delete(_usersTableName,
//        where: "path = ?", whereArgs: [user.selfReference.path]);
//  }
//
//  Future<void> deleteAllUsers() async {
//    db.delete(_usersTableName);
//  }
//}
