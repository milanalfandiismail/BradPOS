import '../../../../../core/database/database_helper.dart';
import '../../models/inventory_item_model.dart';
import '../../models/category_model.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../domain/entities/category.dart';
import 'package:sqflite/sqflite.dart';

abstract class InventoryLocalDataSource {
  Future<List<InventoryItemModel>> getInventory(String userId, {int? limit, int? offset});
  Future<int> getInventoryCount(String userId);
  Future<InventoryItemModel> addInventoryItem(InventoryItem item);
  Future<InventoryItemModel> updateInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(String id, String userId);
  Future<bool> isProductNameExists(String name, String userId, {String? excludeId});

  Future<List<CategoryModel>> getCategories(String userId);
  Future<CategoryModel> addCategory(Category category);
  Future<void> saveCategories(List<CategoryModel> categories);
  Future<void> saveInventoryItems(List<InventoryItemModel> items);

  Future<List<Map<String, dynamic>>> getUnsyncedItems();
  Future<List<Map<String, dynamic>>> getUnsyncedCategories();
  Future<void> updateSyncStatus(String id, String status, {String tableName = 'produk'});
  Future<void> updateItemImage(String id, String imageUrl);
  Future<void> migrateOfflineData(String newUserId);
}

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final DatabaseHelper dbHelper;

  InventoryLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<InventoryItemModel>> getInventory(String userId, {int? limit, int? offset}) async {
    final db = await dbHelper.database;
    // Ambil data yang statusnya BUKAN 'deleted'
    final maps = await db.query(
      'produk',
      where: 'owner_id = ? AND sync_status != ?',
      whereArgs: [userId, 'deleted'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) {
      // Ubah int dari SQLite ke boolean untuk is_active
      final modMap = Map<String, dynamic>.from(map);
      modMap['is_active'] = modMap['is_active'] == 1;
      return InventoryItemModel.fromMap(modMap);
    }).toList();
  }

  @override
  Future<int> getInventoryCount(String userId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM produk WHERE owner_id = ? AND sync_status != ?',
      [userId, 'deleted'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<InventoryItemModel> addInventoryItem(InventoryItem item) async {
    final db = await dbHelper.database;
    final itemModel = InventoryItemModel.fromEntity(item);

    final map = itemModel.toJson();
    map['is_active'] = (map['is_active'] as bool) ? 1 : 0;
    map['sync_status'] = 'created';
    map['updated_at'] = DateTime.now().toIso8601String();

    await db.insert(
      'produk',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return itemModel;
  }

  @override
  Future<InventoryItemModel> updateInventoryItem(InventoryItem item) async {
    final db = await dbHelper.database;
    final itemModel = InventoryItemModel.fromEntity(item);

    final map = itemModel.toJson();
    map['is_active'] = (map['is_active'] as bool) ? 1 : 0;

    // Cek status saat ini
    final current = await db.query(
      'produk',
      where: 'id = ?',
      whereArgs: [item.id],
      limit: 1,
    );
    String nextSyncStatus = 'updated';
    if (current.isNotEmpty && current.first['sync_status'] == 'created') {
      // Jika masih created (belum pernah dikirim ke remote), tetap created
      nextSyncStatus = 'created';
    }

    map['sync_status'] = nextSyncStatus;
    map['updated_at'] = DateTime.now().toIso8601String();

    await db.update(
      'produk',
      map,
      where: 'id = ? AND owner_id = ?',
      whereArgs: [item.id, item.ownerId],
    );

    return itemModel;
  }

  @override
  Future<void> deleteInventoryItem(String id, String userId) async {
    final db = await dbHelper.database;

    // Cek status saat ini
    final current = await db.query(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (current.isNotEmpty && current.first['sync_status'] == 'created') {
      // Jika belum disinkronisasi sama sekali, hapus secara permanen di lokal
      await db.delete(
        'produk',
        where: 'id = ? AND owner_id = ?',
        whereArgs: [id, userId],
      );
    } else {
      // Jika sudah ada di server, tandai sebagai deleted agar disinkronisasikan nanti
      await db.update(
        'produk',
        {
          'sync_status': 'deleted',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND owner_id = ?',
        whereArgs: [id, userId],
      );
    }
  }

  @override
  Future<List<CategoryModel>> getCategories(String userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'categories',
      where: 'owner_id = ? AND sync_status != ?',
      whereArgs: [userId, 'deleted'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<CategoryModel> addCategory(Category category) async {
    final db = await dbHelper.database;
    final catModel = CategoryModel.fromEntity(category);

    final map = catModel.toJson();
    map['sync_status'] = 'created';
    map['updated_at'] = DateTime.now().toIso8601String();

    await db.insert(
      'categories',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return catModel;
  }

  @override
  Future<void> saveCategories(List<CategoryModel> categories) async {
    final db = await dbHelper.database;

    for (var cat in categories) {
      // Cek apakah kategori ini sudah ada di lokal dan statusnya belum sinkron
      final localCats = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [cat.id],
      );

      if (localCats.isNotEmpty) {
        final localStatus = localCats.first['sync_status'] as String;
        // Jika data lokal belum sinkron (ada perubahan offline), jangan timpa dari server
        if (localStatus != 'synced') {
          continue;
        }
      }

      final map = cat.toJson();
      map['sync_status'] = 'synced';
      // Gunakan jam dari server agar hashCode stabil
      map['updated_at'] = cat.updatedAt.toIso8601String();
      
      await db.insert(
        'categories', 
        map, 
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
  }

  @override
  Future<bool> isProductNameExists(String name, String userId, {String? excludeId}) async {
    final db = await dbHelper.database;
    String whereClause = 'name = ? AND owner_id = ? AND is_active = 1';
    List<dynamic> whereArgs = [name, userId];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      'produk',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.isNotEmpty;
  }

  @override
  Future<void> saveInventoryItems(List<InventoryItemModel> items) async {
    final db = await dbHelper.database;
    
    for (var item in items) {
      // Cek apakah item ini sudah ada di lokal dan statusnya belum sinkron
      final localItems = await db.query(
        'produk',
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (localItems.isNotEmpty) {
        final localStatus = localItems.first['sync_status'] as String;
        // Jika data lokal belum sinkron (ada perubahan offline), jangan timpa dari server
        if (localStatus != 'synced') {
          continue;
        }
      }

      final map = item.toJson();
      map['is_active'] = (map['is_active'] as bool) ? 1 : 0;
      map['sync_status'] = 'synced';
      // Gunakan jam dari server agar hashCode stabil
      map['updated_at'] = item.updatedAt.toIso8601String();
      
      await db.insert(
        'produk', 
        map, 
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUnsyncedItems() async {
    final db = await dbHelper.database;
    return await db.query(
      'produk',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getUnsyncedCategories() async {
    final db = await dbHelper.database;
    return await db.query(
      'categories',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
    );
  }

  @override
  Future<void> updateSyncStatus(String id, String status, {String tableName = 'produk'}) async {
    final db = await dbHelper.database;
    if (status == 'deleted_synced') {
      // Setelah berhasil disinkronisasi penghapusannya, hapus dari lokal permanen
      await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update(
        tableName,
        {'sync_status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
  @override
  Future<void> updateItemImage(String id, String imageUrl) async {
    final db = await dbHelper.database;
    await db.update(
      'produk',
      {'image_url': imageUrl},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  @override
  Future<void> migrateOfflineData(String newUserId) async {
    final db = await dbHelper.database;
    // Pindahkan produk milik offline_guest atau id kosong ke user ID yang baru
    await db.update(
      'produk',
      {'owner_id': newUserId},
      where: "owner_id = ? OR owner_id = ? OR owner_id IS NULL",
      whereArgs: ['offline_guest', ''],
    );
    // Pindahkan kategori milik offline_guest ke user ID yang baru
    await db.update(
      'categories',
      {'owner_id': newUserId},
      where: "owner_id = ? OR owner_id = ? OR owner_id IS NULL",
      whereArgs: ['offline_guest', ''],
    );
  }
}
