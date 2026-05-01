import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:bradpos/data/data_sources/inventory_local_data_source.dart';
import 'package:bradpos/data/data_sources/inventory_remote_data_source.dart';
import 'package:bradpos/data/data_sources/transaction_local_data_source.dart';
import 'package:bradpos/data/data_sources/transaction_remote_data_source.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';

class SyncService {
  final SupabaseClient supabase;
  final InventoryLocalDataSource localDataSource;
  final InventoryRemoteDataSource remoteDataSource;
  final TransactionLocalDataSource transactionLocalDataSource;
  final TransactionRemoteDataSource transactionRemoteDataSource;
  final AuthRepository authRepository;
  bool _isSyncing = false;

  SyncService({
    required this.supabase,
    required this.localDataSource,
    required this.remoteDataSource,
    required this.transactionLocalDataSource,
    required this.transactionRemoteDataSource,
    required this.authRepository,
  });

  Future<void> syncAll({int? limit, int? offset}) async {
    if (_isSyncing) {
      return;
    }

    final userResult = await authRepository.getCurrentUser();
    final user = userResult.getOrElse(() => null);

    if (user == null) {
      debugPrint(
        "SyncService: Skip sync karena user belum login atau sesi hilang",
      );
      return;
    }

    final String effectiveUserId = (user.isKaryawan && user.ownerId != null)
        ? user.ownerId!
        : user.id;

    _isSyncing = true;
    try {
      debugPrint(
        "SyncService: Memulai sinkronisasi untuk user ${user.id} (Role: ${user.role}, Effective ID: $effectiveUserId)",
      );

      await authRepository.refreshShopName();

      await _pushUnsyncedCategories(effectiveUserId);
      await _pushUnsyncedLocalData(effectiveUserId);
      await _pushUnsyncedTransactions(effectiveUserId);

      await _pullLatestRemoteData(
        effectiveUserId,
        limit: limit,
        offset: offset,
      );
      await _pullLatestTransactions(effectiveUserId);

      debugPrint("SyncService: Sinkronisasi selesai");
    } catch (e) {
      debugPrint("SyncService Error Utama: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushUnsyncedLocalData(String userId) async {
    final unsyncedItems = await localDataSource.getUnsyncedItems();
    debugPrint(
      "SyncService: Menemukan ${unsyncedItems.length} produk yang perlu disinkronkan (push)",
    );

    for (var itemMap in unsyncedItems) {
      try {
        final status = itemMap['sync_status'] as String;
        String id = itemMap['id'] as String;
        final ownerId = itemMap['owner_id'] as String?;

        if (id.isEmpty) {
          continue;
        }

        // FIX: Supabase butuh UUID. Jika ID lokal abang (1777...) bukan UUID, ganti sekarang.
        if (id.length != 36 || !id.contains('-')) {
          final oldId = id;
          final newUuid = const Uuid().v4();
          debugPrint("SyncService: Ganti ID non-UUID $oldId -> $newUuid");
          await localDataSource.fixInvalidId(oldId, newUuid);
          
          // Update data buat dikirim ke remote
          itemMap = Map<String, dynamic>.from(itemMap);
          itemMap['id'] = newUuid;
          id = newUuid;
        }

        if (ownerId == 'offline_guest' || ownerId == null || ownerId.isEmpty) {
          continue;
        }

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
          try {
            await remoteDataSource.pushDeletedItem(id, userId);
            await localDataSource.updateSyncStatus(id, 'deleted_synced');
          } catch (e) {
            debugPrint("SyncService: Gagal hapus produk $id di server: $e");
          }
        }
      } catch (e) {
        debugPrint("Gagal sync item ${itemMap['id']}: $e");
      }
    }
  }

  Future<void> _pushUnsyncedCategories(String userId) async {
    try {
      final unsyncedCategories = await localDataSource.getUnsyncedCategories();
      for (var catMap in unsyncedCategories) {
        try {
          final ownerId = catMap['owner_id'] as String?;
          if (ownerId == 'offline_guest' || ownerId == null || ownerId.isEmpty) {
            continue;
          }

          await remoteDataSource.pushCreatedCategory(catMap);
          await localDataSource.updateSyncStatus(
            catMap['id'],
            'synced',
            tableName: 'categories',
          );
        } catch (e) {
          debugPrint("Gagal sync category ${catMap['id']}: $e");
        }
      }
    } catch (e) {
      debugPrint("Gagal get unsynced categories: $e");
    }
  }

  Future<void> _pushUnsyncedTransactions(String userId) async {
    try {
      final unsyncedTrxs = await transactionLocalDataSource
          .getUnsyncedTransactions();
      debugPrint(
        "SyncService: Menemukan ${unsyncedTrxs.length} transaksi yang perlu disinkronkan (push)",
      );

      for (var trxMap in unsyncedTrxs) {
        try {
          String id = trxMap['id'] as String;

          if (id.isEmpty) {
            continue;
          }

          // FIX: Supabase butuh UUID. Jika ID lokal bukan UUID, ganti sekarang.
          if (id.length != 36 || !id.contains('-')) {
            final oldId = id;
            final newUuid = const Uuid().v4();
            debugPrint("SyncService: Ganti ID Transaksi non-UUID $oldId -> $newUuid");
            await transactionLocalDataSource.fixInvalidTransactionId(oldId, newUuid);
            
            trxMap = Map<String, dynamic>.from(trxMap);
            trxMap['id'] = newUuid;
            id = newUuid;
          }

          debugPrint("SyncService: Mensinkronkan transaksi $id ke server...");

          final cleanTrx = Map<String, dynamic>.from(trxMap);
          cleanTrx.remove('sync_status');
          cleanTrx.remove('updated_at');

          await transactionRemoteDataSource.pushUnsyncedTransaction(
            cleanTrx,
            [],
          );
          await transactionLocalDataSource.updateSyncStatus(id, 'synced');
        } catch (e) {
          debugPrint("Gagal sync transaksi ${trxMap['id']}: $e");
        }
      }
    } catch (e) {
      debugPrint("Gagal get unsynced transactions: $e");
    }
  }

  Future<void> _pullLatestRemoteData(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    debugPrint(
      "SyncService: Skip pull inventory - local SQLite adalah master untuk stok",
    );

    // Sync categories only (inventory stock dikelola lokal)
    if (offset == null || offset == 0) {
      final remoteCategories = await remoteDataSource.getCategories(userId);
      await localDataSource.saveCategories(remoteCategories);
    }
  }

  Future<void> _pullLatestTransactions(String userId) async {
    debugPrint("SyncService: Menarik data transaksi terbaru dari server...");
    try {
      final remoteTrxs = await transactionRemoteDataSource.getTransactions(
        userId,
      );
      final activeRemoteTrxs = remoteTrxs
          .where((t) => t.status != 'deleted')
          .toList();
      await transactionLocalDataSource.saveTransactions(activeRemoteTrxs);
      // Items are already included in TransactionModel via JSON column
    } catch (e) {
      debugPrint("SyncService: Gagal tarik transaksi: $e");
    }
  }
}
