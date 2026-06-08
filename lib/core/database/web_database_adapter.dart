import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqlite_api;
import 'package:sqflite_common/sqlite_api.dart';

// Re-export ConflictAlgorithm for compatibility
typedef ConflictAlgorithm = sqlite_api.ConflictAlgorithm;

class Sqflite {
  static int? firstIntValue(List<Map<String, dynamic>> list) {
    if (list.isNotEmpty) {
      final firstRow = list.first;
      if (firstRow.isNotEmpty) {
        return firstRow.values.first as int?;
      }
    }
    return null;
  }
}

class WebDatabaseAdapter {
  late Database _db;

  Future<void> init(
    String path, {
    int? version,
    Future<void> Function(Database db, int version)? onCreate,
    Future<void> Function(Database db, int oldVersion, int newVersion)? onUpgrade,
  }) async {
    debugPrint("Initializing SQL Web Database (V1.1.1 Default Factory): $path");
    
    // Use the default factory directly as it proved successful in fallback
    final factory = databaseFactoryFfiWeb;
    
    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: onCreate != null ? (db, v) => onCreate(db, v) : null,
        onUpgrade: onUpgrade != null ? (db, ov, nv) => onUpgrade(db, ov, nv) : null,
      ),
    );
    
    debugPrint("SQL Web: Database opened successfully.");
  }

  // Batch support
  Batch batch() => _db.batch();

  Future<int> insert(String table, Map<String, dynamic> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    return await _db.insert(
      table, 
      values, 
      nullColumnHack: nullColumnHack, 
      conflictAlgorithm: conflictAlgorithm
    );
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await _db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return await _db.rawQuery(sql, arguments);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    return await _db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    return await _db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    await _db.execute(sql, arguments);
  }

  Future<T> transaction<T>(Future<T> Function(dynamic txn) action) async {
    return await _db.transaction(action);
  }

  Future<void> close() async {
    await _db.close();
  }
}
