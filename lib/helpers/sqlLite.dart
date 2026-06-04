import "package:flutter/foundation.dart";
import "package:sqflite/sqflite.dart";
import "package:path/path.dart" as pth;
import "../model/user.dart";

class SQLHelpers {
  static Database? _database;

  // Cached database instance for better performance
  static Future<Database> get _db async {
    _database ??= await initDatabase();
    return _database!;
  }

  static Future<Database> getDatabase() async => _db;

  static Future<Database> initDatabase() async {
    String path = pth.join(await getDatabasesPath(), "dittox_user.db");
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<String> updateUserAccessToken(
      String userId, String newAccessToken) async {
    Database db = await _db;

    // Check if the user with the given userId exists
    var user = await getUserById(userId);
    if (user.isNotEmpty) {
      // User found, update the userAccessToken
      await db.rawUpdate('''
        UPDATE users
        SET userAccessToken = ?
        WHERE userId = ?
      ''', [newAccessToken, userId]);
      return 'UserAccessToken updated successfully for userId: $userId';
    } else {
      return 'User with userId: $userId not found';
    }
  }

  static Future _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE users(
  userId TEXT PRIMARY KEY,
  userName TEXT,
  userEmail TEXT,
  userPlaceName TEXT,
  latitude DOUBLE DEFAULT 12.9716,
  longitude DOUBLE DEFAULT 77.5946,
  userPhoneNumber TEXT,
  userContryName TEXT,
  userAccessToken TEXT
)
''');
  }

//   static Future _onCreate(Database db, int version) async {
//     await db.execute('''
// CREATE TABLE users(
//   userId TEXT PRIMARY KEY,
//   userName TEXT,
//   userEmail TEXT,
//   userPlaceName TEXT,
//   latitude DOUBLE,
//   longitude DOUBLE,
//   userPhoneNumber TEXT,
//   userContryName TEXT
// )
// ''');
//     debugPrint("on create was called");
//   }

  static void getAllTableData(String tableName) async {
    if (!kDebugMode) return;
    Database db = await _db;
    var data = await db.query(tableName);
    debugPrint("SQL $tableName rows: ${data.length}");
  }

  static Future<Map<String, dynamic>> getLatestUser(String tableName) async {
    Database db = await _db;
    var data = await db.query(
      tableName,
      orderBy: 'ROWID DESC',
      limit: 1,
    );
    if (data.isNotEmpty) {
      return data.first;
    }
    return {};
  }

  

  static Future<void> insertUser(Users usr) async {
    Database db = await _db;
    await db.insert(
      "users",
      usr.toMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Debug only - comment out in production for better performance
    // getAllTableData("users");
  }

  static Future<Map<String, dynamic>> getUserById(String id) async {
    Database db = await _db;
    var data = await db.query(
      "users",
      where: "userId = ?",
      whereArgs: [id],
      limit: 1,
    );
    if (data.isEmpty) {
      return {};
    }
    return data.first;
  }

  static Future<Map<String, dynamic>> getUserByAccessToken(
      String accessToken) async {
    Database db = await _db;
    var data = await db.query(
      "users",
      where: "userAccessToken = ?",
      whereArgs: [accessToken],
      limit: 1,
    );
    return data.isEmpty ? {} : data.first;
  }

  static Future<bool> checkUserPresent(String id) async {
    Database db = await _db;
    var data = await db.query(
      "users",
      columns: ["userId"],
      where: "userId = ?",
      whereArgs: [id],
      limit: 1,
    );
    return data.isEmpty;
  }
}
