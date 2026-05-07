import 'package:bradpos/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

abstract class ProfileLocalDataSource {
  Future<Map<String, dynamic>?> getProfile(String id);
  Future<void> saveProfile(Map<String, dynamic> data);
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final DatabaseHelper dbHelper;

  ProfileLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<Map<String, dynamic>?> getProfile(String id) async {
    try {
      final db = await dbHelper.database;
      final maps = await db.query('profiles', where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return maps.first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveProfile(Map<String, dynamic> data) async {
    final db = await dbHelper.database;
    await db.insert('profiles', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
