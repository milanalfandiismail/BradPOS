import 'package:bradpos/core/database/database_helper.dart';
import 'package:bradpos/core/database/db_utils.dart';

abstract class KaryawanLocalDataSource {
  Future<List<Map<String, dynamic>>> getKaryawans(String ownerId, {bool? isActive});
  Future<void> saveKaryawans(List<Map<String, dynamic>> karyawans);
  Future<void> saveKaryawan(Map<String, dynamic> karyawan);
  Future<void> deleteKaryawan(String id);
}

class KaryawanLocalDataSourceImpl implements KaryawanLocalDataSource {
  final DatabaseHelper dbHelper;

  KaryawanLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<Map<String, dynamic>>> getKaryawans(String ownerId, {bool? isActive}) async {
    final db = await dbHelper.database;
    String whereClause = 'owner_id = ?';
    List<dynamic> whereArgs = [ownerId];

    if (isActive != null) {
      whereClause += ' AND is_active = ?';
      whereArgs.add(isActive ? 1 : 0);
    }

    return await db.query(
      'karyawan',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
  }

  @override
  Future<void> saveKaryawans(List<Map<String, dynamic>> karyawans) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var item in karyawans) {
      batch.insert('karyawan', item, conflictAlgorithm: DbUtils.getConflictAlgorithmReplace());
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveKaryawan(Map<String, dynamic> karyawan) async {
    final db = await dbHelper.database;
    await db.insert('karyawan', karyawan, conflictAlgorithm: DbUtils.getConflictAlgorithmReplace());
  }

  @override
  Future<void> deleteKaryawan(String id) async {
    final db = await dbHelper.database;
    await db.delete('karyawan', where: 'id = ?', whereArgs: [id]);
  }
}
