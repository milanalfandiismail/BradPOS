import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:bradpos/data/data_sources/inventory_local_data_source.dart';
import 'package:bradpos/data/data_sources/inventory_remote_data_source.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';

class SyncService {
  final SupabaseClient supabase;
  final InventoryLocalDataSource localDataSource;
  final InventoryRemoteDataSource remoteDataSource;
  final AuthRepository authRepository;
  bool _isSyncing = false;

  SyncService({
    required this.supabase,
    required this.localDataSource,
    required this.remoteDataSource,
    required this.authRepository,
  });

  Future<void> syncAll({int? limit, int? offset}) async {
    if (_isSyncing) {
      return;
    }

    // Ambil data user lengkap (Owner vs Karyawan)
    final userResult = await authRepository.getCurrentUser();
    final user = userResult.getOrElse(() => null);

    if (user == null) {
      debugPrint("SyncService: Skip sync karena user belum login atau sesi hilang");
      return;
    }

    // Jika karyawan, gunakan ownerId untuk menarik/mengirim data
    // Jika owner, gunakan id milik sendiri
    final String effectiveUserId = (user.isKaryawan && user.ownerId != null) 
        ? user.ownerId! 
        : user.id;

    _isSyncing = true;
    try {
      debugPrint("SyncService: Memulai sinkronisasi untuk user ${user.id} (Role: ${user.role}, Effective ID: $effectiveUserId)");
      
      // 0. REFRESH: Nama Toko (Sinkronisasi Profil)
      await authRepository.refreshShopName();

      // 1. PUSH: Kirim perubahan lokal ke server
      // Tetap gunakan userId asli (bukan effective) jika ingin mencatat siapa yg ubah,
      // TAPI di Supabase RLS biasanya dicek berdasarkan owner_id.
      // Jadi kita gunakan effectiveUserId agar data masuk ke bucket owner yg benar.
      await _pushUnsyncedCategories(effectiveUserId);
      await _pushUnsyncedLocalData(effectiveUserId);

      // 2. PULL: Ambil data terbaru dari server (Gunakan ID Owner agar data sinkron)
      await _pullLatestRemoteData(effectiveUserId, limit: limit, offset: offset);

      debugPrint("SyncService: Sinkronisasi selesai");
    } catch (e) {
      debugPrint("SyncService Error Utama: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushUnsyncedLocalData(String userId) async {
    // Ambil data dari SQLite yang sync_status != 'synced'
    final unsyncedItems = await localDataSource.getUnsyncedItems();
    debugPrint("SyncService: Menemukan ${unsyncedItems.length} produk yang perlu disinkronkan (push)");

    for (var itemMap in unsyncedItems) {
      try {
        final status = itemMap['sync_status'] as String;
        final id = itemMap['id'] as String;
        final ownerId = itemMap['owner_id'] as String?;

        // JANGAN sinkronisasi data yang masih berstatus 'offline_guest'
        if (ownerId == 'offline_guest' || ownerId == null || ownerId.isEmpty) {
          debugPrint("SyncService: Melewati produk $id karena owner_id adalah '$ownerId'");
          continue;
        }

        debugPrint("SyncService: Mensinkronkan produk $id ($status) ke server...");
        
        if (status == 'created') {
          final newImageUrl = await remoteDataSource.pushCreatedItem(itemMap);
          if (newImageUrl != null) {
            await localDataSource.updateItemImage(id, newImageUrl);
          }
          await localDataSource.updateSyncStatus(id, 'synced');
        } else if (status == 'updated') {
          final newImageUrl = await remoteDataSource.pushUpdatedItem(itemMap);
          if (newImageUrl != null) {
            await localDataSource.updateItemImage(id, newImageUrl);
          }
          await localDataSource.updateSyncStatus(id, 'synced');
        } else if (status == 'deleted') {
          debugPrint("SyncService: Proses delete produk $id...");
          try {
            await remoteDataSource.pushDeletedItem(id, userId);
            await localDataSource.updateSyncStatus(id, 'deleted_synced');
            debugPrint("SyncService: Produk $id dihapus dari lokal setelah sync berhasil");
          } catch (e) {
            debugPrint("SyncService: Gagal hapus produk $id di server: $e");
          }
        }
      } catch (e) {
        debugPrint("Gagal sync item ${itemMap['id']}: $e");
        // Jika gagal, biarkan saja. Nanti dicoba lagi pada sync berikutnya.
      }
    }
  }

  Future<void> _pushUnsyncedCategories(String userId) async {
    try {
      final unsyncedCategories = await localDataSource.getUnsyncedCategories();
      debugPrint("SyncService: Menemukan ${unsyncedCategories.length} kategori yang perlu disinkronkan (push)");

      for (var catMap in unsyncedCategories) {
        try {
          final ownerId = catMap['owner_id'] as String?;
          if (ownerId == 'offline_guest' || ownerId == null || ownerId.isEmpty) {
            debugPrint("SyncService: Melewati kategori ${catMap['id']} karena owner_id adalah '$ownerId'");
            continue;
          }
          
          debugPrint("SyncService: Mensinkronkan kategori ${catMap['id']} ke server...");
          await remoteDataSource.pushCreatedCategory(catMap);
          // Update status di lokal jika berhasil
          await localDataSource.updateSyncStatus(catMap['id'], 'synced', tableName: 'categories');
        } catch (e) {
          debugPrint("Gagal sync category ${catMap['id']}: $e");
        }
      }
    } catch (e) {
      debugPrint("Gagal get unsynced categories: $e");
    }
  }

  Future<void> _pullLatestRemoteData(String userId, {int? limit, int? offset}) async {
    debugPrint("SyncService: Menarik data terbaru dari server (limit: $limit, offset: $offset)...");
    // Tarik data inventory dari Supabase
    final remoteItems = await remoteDataSource.getInventory(userId, limit: limit, offset: offset);
    debugPrint("SyncService: Berhasil menarik ${remoteItems.length} produk dari server");
    await localDataSource.saveInventoryItems(remoteItems);

    // Tarik data category dari Supabase (Selalu semua karena biasanya sedikit)
    if (offset == null || offset == 0) {
      final remoteCategories = await remoteDataSource.getCategories(userId);
      debugPrint("SyncService: Berhasil menarik ${remoteCategories.length} kategori dari server");
      await localDataSource.saveCategories(remoteCategories);
    }
  }
}
