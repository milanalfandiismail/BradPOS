import 'package:bradpos/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

abstract class KaryawanLocalDataSource {
  Future<List<Map<String, dynamic>>> getKaryawans(String ownerId);
  Future<void> saveKaryawans(List<Map<String, dynamic>> karyawans);
  Future<void> saveKaryawan(Map<String, dynamic> karyawan);
  Future<void> deleteKaryawan(String id);
}

class KaryawanLocalDataSourceImpl implements KaryawanLocalDataSource {
  final DatabaseHelper dbHelper;

  KaryawanLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<Map<String, dynamic>>> getKaryawans(String ownerId) async {
    final db = await dbHelper.database;
    return await db.query(
      'karyawan',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at DESC',
    );
  }

  @override
  Future<void> saveKaryawans(List<Map<String, dynamic>> karyawans) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var item in karyawans) {
      batch.insert('karyawan', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveKaryawan(Map<String, dynamic> karyawan) async {
    final db = await dbHelper.database;
    await db.insert('karyawan', karyawan, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteKaryawan(String id) async {
    final db = await dbHelper.database;
    await db.delete('karyawan', where: 'id = ?', whereArgs: [id]);
  }
}
