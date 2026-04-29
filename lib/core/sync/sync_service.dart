import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../features/inventory/data/data_sources/local/inventory_local_data_source.dart';
import '../../features/inventory/data/data_sources/remote/inventory_remote_data_source.dart';

class SyncService {
  final SupabaseClient supabase;
  final InventoryLocalDataSource localDataSource;
  final InventoryRemoteDataSource remoteDataSource;
  bool _isSyncing = false;

  SyncService({
    required this.supabase,
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint("SyncService: Skip sync karena sedang ada proses sinkronisasi berjalan");
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint("SyncService: Skip sync karena user belum login");
      return;
    }

    _isSyncing = true;
    try {
      debugPrint("SyncService: Memulai sinkronisasi untuk user $userId");
      
      // 1. PUSH: Kirim perubahan lokal ke server (Prioritas agar edit lokal tidak tertimpa data lama)
      await _pushUnsyncedCategories(userId);
      await _pushUnsyncedLocalData(userId);

      // 2. PULL: Ambil data terbaru dari server
      await _pullLatestRemoteData(userId);

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
          await remoteDataSource.pushDeletedItem(id, userId);
          // Hapus permanen di lokal jika berhasil
          await localDataSource.updateSyncStatus(id, 'deleted_synced');
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

  Future<void> _pullLatestRemoteData(String userId) async {
    debugPrint("SyncService: Menarik data terbaru dari server...");
    // Tarik data inventory dari Supabase
    final remoteItems = await remoteDataSource.getInventory(userId);
    debugPrint("SyncService: Berhasil menarik ${remoteItems.length} produk dari server");
    await localDataSource.saveInventoryItems(remoteItems);

    // Tarik data category dari Supabase
    final remoteCategories = await remoteDataSource.getCategories(userId);
    debugPrint("SyncService: Berhasil menarik ${remoteCategories.length} kategori dari server");
    await localDataSource.saveCategories(remoteCategories);
  }
}
