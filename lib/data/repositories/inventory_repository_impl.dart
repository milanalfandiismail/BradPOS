import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/domain/entities/category.dart';
import 'package:bradpos/domain/repositories/inventory_repository.dart';
import 'package:bradpos/data/data_sources/inventory_local_data_source.dart';
import 'package:bradpos/data/data_sources/inventory_remote_data_source.dart';
import 'package:bradpos/data/data_sources/category_local_data_source.dart';
import 'package:bradpos/data/models/inventory_item_model.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/core/sync/sync_service.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final SupabaseClient supabase;
  final InventoryLocalDataSource localDataSource;
  final InventoryRemoteDataSource remoteDataSource;
  final CategoryLocalDataSource categoryLocalDataSource;
  final AuthRepository authRepository;
  final SyncService syncService;

  InventoryRepositoryImpl({
    required this.supabase,
    required this.localDataSource,
    required this.remoteDataSource,
    required this.categoryLocalDataSource,
    required this.authRepository,
    required this.syncService,
  });

  Future<String?> _getUserId() async {
    final userResult = await authRepository.getCurrentUser();
    return userResult.fold((failure) => 'offline_guest', (user) {
      if (user == null) return 'offline_guest';
      if (user.role == 'karyawan') return user.ownerId;
      return user.id;
    });
  }

  @override
  Future<Either<String, List<InventoryItem>>> getInventory({
    int? limit,
    int? offset,
    String? searchQuery,
    String? category,
    String? stockStatus,
    bool skipSync = false,
  }) async {
    try {
      final userId = await _getUserId() ?? 'offline_guest';
      final localItems = await localDataSource.getInventory(
        userId,
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
        category: category,
        stockStatus: stockStatus,
      );
      return Right(localItems);
    } catch (e) {
      return Left("Gagal memuat data inventory: $e");
    }
  }

  @override
  Future<Either<String, int>> getInventoryCount({
    String? searchQuery,
    String? category,
    String? stockStatus,
  }) async {
    try {
      final userId = await _getUserId() ?? 'offline_guest';
      final count = await localDataSource.getInventoryCount(
        userId,
        searchQuery: searchQuery,
        category: category,
        stockStatus: stockStatus,
      );
      return Right(count);
    } catch (e) {
      return Left("Gagal menghitung data: $e");
    }
  }

  @override
  Future<Either<String, InventoryItem>> addInventoryItem(
    InventoryItem item,
  ) async {
    try {
      final userId = await _getUserId() ?? 'offline_guest';
      var newItem = item.copyWith(ownerId: userId);

      if (newItem.categoryId == null && newItem.category.isNotEmpty) {
        final existingCats = await categoryLocalDataSource.getCategories(userId);
        final match = existingCats.where(
          (c) => c.name.trim().toLowerCase() == newItem.category.trim().toLowerCase(),
        ).toList();

        if (match.isNotEmpty) {
          newItem = newItem.copyWith(categoryId: match.first.id);
        } else {
          final newCat = Category(
            id: const Uuid().v4(),
            ownerId: userId,
            name: newItem.category,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await categoryLocalDataSource.addCategory(newCat);
          newItem = newItem.copyWith(categoryId: newCat.id);
        }
      }

      final savedLocal = await localDataSource.addInventoryItem(newItem);
      await _pushItemToRemote(newItem.copyWith(id: savedLocal.id));

      return Right(savedLocal);
    } catch (e) {
      return Left("Gagal menambah item: $e");
    }
  }

  @override
  Future<Either<String, InventoryItem>> updateInventoryItem(
    InventoryItem item,
  ) async {
    try {
      final userId = await _getUserId() ?? 'offline_guest';
      var updatedItem = item;

      if (updatedItem.categoryId == null && updatedItem.category.isNotEmpty) {
        final existingCats = await categoryLocalDataSource.getCategories(userId);
        final match = existingCats.where(
          (c) => c.name.trim().toLowerCase() == updatedItem.category.trim().toLowerCase(),
        ).toList();

        if (match.isNotEmpty) {
          updatedItem = updatedItem.copyWith(categoryId: match.first.id);
        } else {
          final newCat = Category(
            id: const Uuid().v4(),
            ownerId: userId,
            name: updatedItem.category,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await categoryLocalDataSource.addCategory(newCat);
          updatedItem = updatedItem.copyWith(categoryId: newCat.id);
        }
      }

      final updatedLocal = await localDataSource.updateInventoryItem(updatedItem);
      await _pushItemToRemote(updatedItem);

      return Right(updatedLocal);
    } catch (e) {
      return Left("Gagal memperbarui item: $e");
    }
  }

  @override
  Future<Either<String, void>> deleteInventoryItem(String id) async {
    try {
      final userId = await _getUserId() ?? 'offline_guest';
      await localDataSource.deleteInventoryItem(id, userId);
      if (userId != 'offline_guest') {
        _pushDeletedItemToRemote(id, userId);
      }
      return const Right(null);
    } catch (e) {
      return Left("Gagal menghapus item: $e");
    }
  }

  @override
  Future<bool> isProductNameExists(String name, {String? excludeId}) async {
    final userId = await _getUserId();
    if (userId == null) return false;
    return await localDataSource.isProductNameExists(
      name,
      userId,
      excludeId: excludeId,
    );
  }

  @override
  Future<bool> hasOfflineData() async {
    try {
      final items = await localDataSource.getInventory('offline_guest');
      return items.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<String, void>> syncOfflineData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return const Left("Harus login untuk sinkronisasi.");
      await localDataSource.migrateOfflineData(userId);
      syncService.syncAll();
      return const Right(null);
    } catch (e) {
      return Left("Gagal sinkronisasi data offline: $e");
    }
  }

  Future<void> _pushItemToRemote(InventoryItem item) async {
    try {
      if (item.ownerId == 'offline_guest') return;
      final itemMap = InventoryItemModel.fromEntity(item).toMap();
      itemMap.remove('sync_status');
      itemMap.remove('updated_at');
      await remoteDataSource.pushCreatedItem(itemMap);
    } catch (e) {
      debugPrint('Immediate sync failed: $e');
    }
  }

  Future<void> _pushDeletedItemToRemote(String id, String userId) async {
    try {
      await remoteDataSource.pushDeletedItem(id, userId);
    } catch (e) {
      debugPrint('Immediate delete sync failed: $e');
    }
  }
}
