import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:bradpos/data/data_sources/inventory_local_data_source.dart';
import 'package:bradpos/data/data_sources/inventory_remote_data_source.dart';

class ProductSyncManager {
  final InventoryLocalDataSource localDataSource;
  final InventoryRemoteDataSource remoteDataSource;

  ProductSyncManager({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<void> push(String userId) async {
    final unsyncedItems = await localDataSource.getUnsyncedItems();
    if (unsyncedItems.isEmpty) return;

    debugPrint("ProductSync: Menemukan ${unsyncedItems.length} produk yang perlu push");

    for (var itemMap in unsyncedItems) {
      try {
        final status = itemMap['sync_status'] as String;
        String id = itemMap['id'] as String;
        final ownerId = itemMap['owner_id'] as String?;
        final name = itemMap['name'] as String? ?? 'Tanpa Nama';

        if (id.isEmpty) continue;

        // UUID Fix
        if (id.length != 36 || !id.contains('-')) {
          final oldId = id;
          final newUuid = const Uuid().v4();
          debugPrint("ProductSync: Fix ID non-UUID '$oldId' ($name) -> $newUuid");
          await localDataSource.fixInvalidId(oldId, newUuid);
          itemMap = Map<String, dynamic>.from(itemMap);
          itemMap['id'] = newUuid;
          id = newUuid;
        }

        if (ownerId == 'offline_guest' || ownerId == null || ownerId.isEmpty) {
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
        } else if (status == 'updated' || status == 'pending_update') {
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
    try {
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
    } catch (e) {
      debugPrint("ProductSync Pull Failed: $e");
    }
  }
}
