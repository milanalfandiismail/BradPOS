import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:bradpos/domain/entities/category.dart';
import 'package:bradpos/domain/repositories/category_repository.dart';
import 'package:bradpos/data/data_sources/category_local_data_source.dart';
import 'package:bradpos/data/data_sources/category_remote_data_source.dart';
import 'package:bradpos/data/data_sources/inventory_local_data_source.dart';
import 'package:bradpos/data/models/category_model.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:bradpos/core/sync/sync_utils.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;
  final CategoryRemoteDataSource remoteDataSource;
  final InventoryLocalDataSource inventoryLocalDataSource;
  final AuthRepository authRepository;

  CategoryRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.inventoryLocalDataSource,
    required this.authRepository,
  });

  String _generateUuid() => const Uuid().v4();

  @override
  Future<Either<String, List<Category>>> getCategories() async {
    try {
      final userId = await SyncUtils.getUserId(authRepository);
      final local = await localDataSource.getCategories(userId);
      final fixed = <Category>[];
      for (var cat in local) {
        if (cat.id.isEmpty || cat.id.length != 36 || !cat.id.contains('-')) {
          final oldId = cat.id;
          final newUuid = _generateUuid();
          debugPrint('CategoryRepo: Fixing legacy ID: $oldId -> $newUuid');
          await localDataSource.fixInvalidCategoryId(oldId, newUuid);
          fixed.add(CategoryModel.fromEntity(cat).copyWith(id: newUuid));
        } else {
          fixed.add(cat);
        }
      }
      return Right(fixed);
    } catch (e) {
      return Left('Gagal memuat kategori: $e');
    }
  }

  @override
  Future<Either<String, Category>> addCategory(Category category) async {
    try {
      final userId = await SyncUtils.getUserId(authRepository);
      
      // Prevent duplicate names locally
      final existingResult = await getCategories();
      final exists = existingResult.fold(
        (_) => false,
        (cats) => cats.any((c) => c.name.toLowerCase() == category.name.toLowerCase()),
      );
      
      if (exists) {
        return Left('Kategori "${category.name}" sudah ada');
      }

      final newCat = category.copyWith(
        id: category.id.isEmpty ? _generateUuid() : category.id,
        ownerId: userId,
      );
      await localDataSource.addCategory(newCat);
      if (userId != SyncUtils.offlineGuest && userId.isNotEmpty) {
        await remoteDataSource.pushCreatedCategory(
          CategoryModel.fromEntity(newCat).toMap(),
        );
      }
      return Right(newCat);
    } catch (e) {
      return Left('Gagal menambah kategori: $e');
    }
  }

  @override
  Future<Either<String, Category>> updateCategory(Category category) async {
    try {
      final userId = await SyncUtils.getUserId(authRepository);
      var cat = category.copyWith(ownerId: userId);

      // Get old name before update to propagate to products
      final oldCat = await localDataSource.getCategoryById(cat.id);
      final oldName = oldCat?.name;

      if (cat.id.isEmpty || cat.id.length != 36 || !cat.id.contains('-')) {
        final oldId = cat.id;
        final newUuid = _generateUuid();
        debugPrint('CategoryRepo: Fixing invalid ID during update: $oldId -> $newUuid');
        await localDataSource.fixInvalidCategoryId(oldId, newUuid);
        cat = cat.copyWith(id: newUuid);
      }

      await localDataSource.updateCategory(cat);

      // Propagate category name change to existing products
      if (oldName != null && oldName != cat.name && userId.isNotEmpty) {
        await inventoryLocalDataSource.updateProductsCategoryName(
          oldName,
          cat.name,
          userId,
        );
      }

      if (userId != SyncUtils.offlineGuest && userId.isNotEmpty) {
        await remoteDataSource.pushUpdatedCategory(
          CategoryModel.fromEntity(cat).toMap(),
        );
      }
      return Right(cat);
    } catch (e) {
      return Left('Gagal memperbarui kategori: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteCategory(String id, String name) async {
    try {
      final userId = await SyncUtils.getUserId(authRepository);
      await localDataSource.deleteCategory(id, userId, name: name);
      if (userId != SyncUtils.offlineGuest && id.isNotEmpty) {
        try {
          await remoteDataSource.updateProductsCategoryToNull(id, userId);
          await remoteDataSource.pushDeletedCategory(id, userId);
          await localDataSource.updateSyncStatus(id, 'deleted_synced');
        } catch (e) {
          debugPrint('CategoryRepo delete remote error (will retry via SyncService): $e');
        }
      }
      return const Right(null);
    } catch (e) {
      return Left('Gagal menghapus kategori: $e');
    }
  }
}
