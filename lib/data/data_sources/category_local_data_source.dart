import 'package:flutter/foundation.dart' hide Category;
import 'package:bradpos/core/database/database_helper.dart';
import 'package:bradpos/data/models/category_model.dart';
import 'package:bradpos/domain/entities/category.dart';
import 'package:sqflite/sqflite.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories(String userId);
  Future<CategoryModel?> getCategoryById(String id);
  Future<CategoryModel> addCategory(Category category);
  Future<CategoryModel> updateCategory(Category category);
  Future<void> deleteCategory(String id, String userId, {String? name});
  Future<void> saveCategories(List<CategoryModel> categories);
  Future<List<Map<String, dynamic>>> getUnsyncedCategories();
  Future<void> updateSyncStatus(String id, String status);
  Future<void> fixInvalidCategoryId(String oldId, String newUuid);
  Future<String?> getLastSyncTime(String userId);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final DatabaseHelper dbHelper;

  CategoryLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<CategoryModel>> getCategories(String userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'categories',
      where: 'owner_id = ? AND sync_status NOT IN (?, ?)',
      whereArgs: [userId, 'deleted', 'deleted_synced'],
      orderBy: 'name ASC',
    );

    for (var m in maps) {
      debugPrint(
        "DEBUG DB category: id=${m['id']}, name=${m['name']}, sync_status=${m['sync_status']}",
      );
    }

    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  @override
  Future<CategoryModel> addCategory(Category category) async {
    final db = await dbHelper.database;
    final model = CategoryModel.fromEntity(category);
    final map = model.toMap();
    map['sync_status'] = 'created';

    await db.insert(
      'categories',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return model;
  }

  @override
  Future<CategoryModel> updateCategory(Category category) async {
    final db = await dbHelper.database;
    final model = CategoryModel.fromEntity(category);
    final map = model.toMap();
    map['sync_status'] = 'updated';

    await db.update(
      'categories',
      map,
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return model;
  }

  @override
  Future<void> deleteCategory(String id, String userId, {String? name}) async {
    final db = await dbHelper.database;

    if (id.isEmpty && name != null) {
      await db.delete(
        'categories',
        where: 'name = ? AND owner_id = ?',
        whereArgs: [name, userId],
      );
      return;
    }

    await db.delete('categories', where: 'id = ?', whereArgs: [id]);

    await db.update(
      'produk',
      {
        'category_id': null,
        'category': 'Tanpa Kategori',
        'sync_status': 'pending_update',
      },
      where: 'category_id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> saveCategories(List<CategoryModel> categories) async {
    final db = await dbHelper.database;

    for (var cat in categories) {
      final localCats = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [cat.id],
      );

      if (localCats.isNotEmpty) {
        final localStatus = localCats.first['sync_status'] as String;
        if (localStatus != 'synced') {
          continue;
        }
      }

      final map = cat.toJson();
      map['sync_status'] = 'synced';
      map['updated_at'] = cat.updatedAt.toIso8601String();

      await db.insert(
        'categories',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
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
  Future<void> updateSyncStatus(String id, String status) async {
    final db = await dbHelper.database;
    if (status == 'deleted_synced') {
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update(
        'categories',
        {'sync_status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  @override
  Future<void> fixInvalidCategoryId(String oldId, String newUuid) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'categories',
        {'id': newUuid},
        where: 'id = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'produk',
        {'category_id': newUuid},
        where: 'category_id = ?',
        whereArgs: [oldId],
      );
    });
  }

  @override
  Future<String?> getLastSyncTime(String userId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(updated_at) as last_sync FROM categories WHERE owner_id = ?',
      [userId],
    );
    if (result.isNotEmpty && result.first['last_sync'] != null) {
      return result.first['last_sync'] as String;
    }
    return null;
  }
}
