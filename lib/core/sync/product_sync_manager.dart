import 'package:flutter/foundation.dart';
import 'package:bradpos/data/data_sources/inventory_local_data_source.dart';
import 'package:bradpos/data/data_sources/inventory_remote_data_source.dart';
import 'package:bradpos/core/sync/sync_utils.dart';

class ProductSyncManager {
  final InventoryLocalDataSource localDataSource;
  final InventoryRemoteDataSource remoteDataSource;

  ProductSyncManager({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<void> push(String userId) async {
    final unsynced = await localDataSource.getUnsyncedItems();
    if (unsynced.isEmpty) return;

    debugPrint("ProductSync: Menemukan ${unsynced.length} produk yang perlu push");

    for (var itemMap in unsynced) {
      try {
        final status = itemMap['sync_status'] as String;
        String id = itemMap['id'] as String;
        final ownerId = itemMap['owner_id'] as String?;
        final name = itemMap['name'] as String? ?? 'Tanpa Nama';

        if (ownerId == null) continue;
        if (SyncUtils.belongsToOtherUser(ownerId, userId)) {
          debugPrint("ProductSync: Skip push '$name' (milik $ownerId, bukan $userId)");
          continue;
        }

        if (id.isEmpty) continue;

        if (SyncUtils.isInvalidUuid(id)) {
          final (oldId, newId) = SyncUtils.fixUuid(id);
          debugPrint("ProductSync: Fix ID non-UUID '$oldId' ($name) -> $newId");
          await localDataSource.fixInvalidId(oldId, newId);
          itemMap = Map<String, dynamic>.from(itemMap);
          itemMap['id'] = newId;
          id = newId;
        }

        if (SyncUtils.isGuestOwner(ownerId)) {
          itemMap = Map<String, dynamic>.from(itemMap);
          itemMap['owner_id'] = userId;
        }

        if (status == 'created') {
          debugPrint("ProductSync: Push (created) produk '$name' ($id)");
          final newImageUrl = await remoteDataSource.pushCreatedItem(itemMap);
          if (newImageUrl != null) {
            await localDataSource.updateItemImage(id, newImageUrl);
          }
          await localDataSource.updateSyncStatus(id, 'synced');
        } else if (SyncUtils.shouldPush(status)) {
          debugPrint("ProductSync: Push (updated) produk '$name' ($id)");
          final newImageUrl = await remoteDataSource.pushUpdatedItem(itemMap);
          if (newImageUrl != null) {
            await localDataSource.updateItemImage(id, newImageUrl);
          }
          await localDataSource.updateSyncStatus(id, 'synced');
        }
      } catch (e) {
        debugPrint("ProductSync Error (${itemMap['id']}): $e");
      }
    }
  }

  Future<void> pull(String userId, {int? limit, int? offset}) async {
    final lastSync = await localDataSource.getLastSyncTime('produk', userId);
    debugPrint("ProductSync: Pulling products from server (Last Sync: $lastSync)...");

    final remoteItems = await remoteDataSource.getInventory(
      userId,
      limit: limit,
      offset: offset,
      lastSync: lastSync,
    );

    if (remoteItems.isEmpty) {
      debugPrint("ProductSync: Tidak ada produk baru di server.");
      return;
    }

    debugPrint("ProductSync: Berhasil menarik ${remoteItems.length} produk");
    await localDataSource.saveInventoryItems(remoteItems);
  }
}
