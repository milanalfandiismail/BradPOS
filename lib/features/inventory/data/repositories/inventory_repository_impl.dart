import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../data_sources/local/inventory_local_data_source.dart';
import '../data_sources/remote/inventory_remote_data_source.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final SupabaseClient supabase;
  final InventoryLocalDataSource localDataSource;
  final InventoryRemoteDataSource remoteDataSource;
  final AuthRepository authRepository;

  InventoryRepositoryImpl({
    required this.supabase,
    required this.localDataSource,
    required this.remoteDataSource,
    required this.authRepository,
  });

  Future<String?> _getUserId() async {
    final userResult = await authRepository.getCurrentUser();
    return userResult.fold(
      (failure) => null,
      (user) {
        if (user == null) return null;
        if (user.role == 'karyawan') return user.ownerId;
        return user.id;
      },
    );
  }

  String _generateUuid() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10xx
    final hexStr = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return '${hexStr.substring(0, 8)}-${hexStr.substring(8, 12)}-${hexStr.substring(12, 16)}-${hexStr.substring(16, 20)}-${hexStr.substring(20)}';
  }

  @override
  Future<Either<String, List<InventoryItem>>> getInventory() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return const Left("Anda harus login terlebih dahulu.");

      // 1. Coba ambil dari lokal terlebih dahulu agar cepat (Offline-First)
      final localItems = await localDataSource.getInventory(userId);
      
      // 2. Jika koneksi tersedia, ambil dari server dan perbarui lokal di background (Silent Sync)
      _syncFromServer(userId);

      return Right(localItems);
    } catch (e) {
      return Left("Gagal memuat data inventory: $e");
    }
  }

  // Fungsi background untuk mensinkronisasi data dari server ke lokal
  Future<void> _syncFromServer(String userId) async {
    if (userId == 'offline_guest') return;
    try {
      final remoteItems = await remoteDataSource.getInventory(userId);
      await localDataSource.saveInventoryItems(remoteItems);
      
      final remoteCategories = await remoteDataSource.getCategories(userId);
      await localDataSource.saveCategories(remoteCategories);
    } catch (e) {
      // Abaikan jika gagal (misal tidak ada internet), data lokal tetap aman
    }
  }

  @override
  Future<Either<String, InventoryItem>> addInventoryItem(InventoryItem item) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return const Left("User tidak terautentikasi.");

      // Set ownerId jika belum ada
      var newItem = item.copyWith(ownerId: userId);

      // Otomatis buat Kategori baru jika dipilih "Lainnya" (categoryId == null tapi ada text)
      if (newItem.categoryId == null && newItem.category.isNotEmpty) {
        final newCat = Category(
          id: _generateUuid(),
          ownerId: userId,
          name: newItem.category,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        // Simpan kategori ke lokal
        final savedCat = await localDataSource.addCategory(newCat);
        
        newItem = newItem.copyWith(categoryId: savedCat.id);
      }

      // Simpan ke lokal (SyncService yang akan menangani push ke server)
      final savedLocal = await localDataSource.addInventoryItem(newItem);

      return Right(savedLocal);
    } catch (e) {
      return Left("Gagal menambah item: $e");
    }
  }

  @override
  Future<Either<String, InventoryItem>> updateInventoryItem(InventoryItem item) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return const Left("User tidak terautentikasi.");

      var updatedItem = item;

      // Otomatis buat Kategori baru jika dipilih "Lainnya"
      if (updatedItem.categoryId == null && updatedItem.category.isNotEmpty) {
        final newCat = Category(
          id: _generateUuid(),
          ownerId: userId,
          name: updatedItem.category,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final savedCat = await localDataSource.addCategory(newCat);
        
        updatedItem = updatedItem.copyWith(categoryId: savedCat.id);
      }

      // Update ke lokal (SyncService yang akan menangani push ke server)
      final updatedLocal = await localDataSource.updateInventoryItem(updatedItem);

      return Right(updatedLocal);
    } catch (e) {
      return Left("Gagal memperbarui item: $e");
    }
  }

  @override
  Future<bool> isProductNameExists(String name, {String? excludeId}) async {
    final userId = await _getUserId();
    if (userId == null) return false;
    return await localDataSource.isProductNameExists(name, userId, excludeId: excludeId);
  }

  @override
  Future<Either<String, List<Category>>> getCategories() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return const Left("Anda harus login terlebih dahulu.");

      // Ambil dari lokal
      final localCategories = await localDataSource.getCategories(userId);

      return Right(localCategories);
    } catch (e) {
      return Left("Gagal memuat kategori: $e");
    }
  }

  @override
  Future<Either<String, void>> deleteInventoryItem(String id) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return const Left("User tidak terautentikasi.");

      // Tandai deleted di lokal (SyncService yang akan menangani hapus di server)
      await localDataSource.deleteInventoryItem(id, userId);

      return const Right(null);
    } catch (e) {
      return Left("Gagal menghapus item: $e");
    }
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
      return const Right(null);
    } catch (e) {
      return Left("Gagal sinkronisasi data offline: $e");
    }
  }
}