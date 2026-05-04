import 'package:bradpos/core/database/database_helper.dart';
import 'package:bradpos/data/models/inventory_item_model.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:sqflite/sqflite.dart';

abstract class InventoryLocalDataSource {
  Future<List<InventoryItemModel>> getInventory(
    String userId, {
    int? limit,
    int? offset,
    String? searchQuery,
    String? category,
    String? stockStatus,
  });
  Future<int> getInventoryCount(
    String userId, {
    String? searchQuery,
    String? category,
    String? stockStatus,
  });

  Future<InventoryItemModel> addInventoryItem(InventoryItem item);
  Future<InventoryItemModel> updateInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(String id, String userId);
  Future<bool> isProductNameExists(
    String name,
    String userId, {
    String? excludeId,
  });

  Future<void> saveInventoryItems(List<InventoryItemModel> items);

  Future<List<Map<String, dynamic>>> getUnsyncedItems();
  Future<void> updateSyncStatus(
    String id,
    String status, {
    String tableName = 'produk',
  });
  Future<void> updateItemImage(String id, String imageUrl);
  Future<void> updateProductsCategoryName(
    String oldName,
    String newName,
    String userId,
  );
  Future<void> migrateOfflineData(String newUserId);
  Future<void> fixInvalidId(String oldId, String newUuid);
  Future<String?> getLastSyncTime(String tableName, String userId);
}

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final DatabaseHelper dbHelper;

  InventoryLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<InventoryItemModel>> getInventory(
    String userId, {
    int? limit,
    int? offset,
    String? searchQuery,
    String? category,
    String? stockStatus,
  }) async {
    final db = await dbHelper.database;

    String whereClause = 'owner_id = ? AND sync_status NOT LIKE ?';
    List<dynamic> whereArgs = [userId, 'deleted%'];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ' AND name LIKE ?';
      whereArgs.add('%$searchQuery%');
    }
    if (category != null && category != 'All') {
      if (category == 'Tanpa Kategori') {
        whereClause +=
            ' AND (category IS NULL OR category = "" OR category = "Tanpa Kategori")';
      } else {
        whereClause += ' AND category = ?';
        whereArgs.add(category);
      }
    }
    if (stockStatus != null && stockStatus != 'All') {
      if (stockStatus == 'Low Stock') {
        whereClause += ' AND stock > 0 AND stock <= 10';
      } else if (stockStatus == 'Out of Stock') {
        whereClause += ' AND stock <= 0 AND stock != -1';
      }
    }

    final maps = await db.query(
      'produk',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'category ASC, name ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) {
      final modMap = Map<String, dynamic>.from(map);
      modMap['is_active'] = modMap['is_active'] == 1;
      return InventoryItemModel.fromMap(modMap);
    }).toList();
  }

  @override
  Future<int> getInventoryCount(
    String userId, {
    String? searchQuery,
    String? category,
    String? stockStatus,
  }) async {
    final db = await dbHelper.database;

    String whereClause = 'owner_id = ? AND sync_status != ?';
    List<dynamic> whereArgs = [userId, 'deleted'];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ' AND name LIKE ?';
      whereArgs.add('%$searchQuery%');
    }
    if (category != null && category != 'All') {
      if (category == 'Tanpa Kategori') {
        whereClause +=
            ' AND (category IS NULL OR category = "" OR category = "Tanpa Kategori")';
      } else {
        whereClause += ' AND category = ?';
        whereArgs.add(category);
      }
    }
    if (stockStatus != null && stockStatus != 'All') {
      if (stockStatus == 'Low Stock') {
        whereClause += ' AND stock > 0 AND stock <= 10';
      } else if (stockStatus == 'Out of Stock') {
        whereClause += ' AND stock <= 0 AND stock != -1';
      }
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM produk WHERE $whereClause',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<InventoryItemModel> addInventoryItem(InventoryItem item) async {
    final db = await dbHelper.database;
    final itemModel = InventoryItemModel.fromEntity(item);

    final map = itemModel.toMap();
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

    final map = itemModel.toMap();

    // Cek status saat ini
    final current = await db.query(
      'produk',
      where: 'id = ?',
      whereArgs: [item.id],
      limit: 1,
    );
    String nextSyncStatus = 'updated';
    if (current.isNotEmpty && current.first['sync_status'] == 'created') {
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

    // Hard delete as requested
    await db.delete('produk', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> isProductNameExists(
    String name,
    String userId, {
    String? excludeId,
  }) async {
    final db = await dbHelper.database;
    String whereClause =
        'name = ? AND owner_id = ? AND is_active = 1 AND sync_status != ?';
    List<dynamic> whereArgs = [name, userId, 'deleted'];

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
        conflictAlgorithm: ConflictAlgorithm.replace,
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
  Future<void> updateSyncStatus(
    String id,
    String status, {
    String tableName = 'produk',
  }) async {
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
  Future<void> updateProductsCategoryName(
    String oldName,
    String newName,
    String userId,
  ) async {
    final db = await dbHelper.database;
    await db.update(
      'produk',
      {'category': newName, 'sync_status': 'pending_update'},
      where: 'category = ? AND owner_id = ?',
      whereArgs: [oldName, userId],
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
    // Pindahkan transaksi milik offline_guest ke user ID yang baru
    await db.update(
      'transactions',
      {'owner_id': newUserId},
      where: "owner_id = ? OR owner_id = ? OR owner_id IS NULL",
      whereArgs: ['offline_guest', ''],
    );
  }

  @override
  Future<void> fixInvalidId(String oldId, String newUuid) async {
    final db = await dbHelper.database;
    await db.update(
      'produk',
      {'id': newUuid},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }

  @override
  Future<String?> getLastSyncTime(String tableName, String userId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(updated_at) as last_sync FROM $tableName WHERE owner_id = ?',
      [userId],
    );
    if (result.isNotEmpty && result.first['last_sync'] != null) {
      return result.first['last_sync'] as String;
    }
    return null;
  }
}
