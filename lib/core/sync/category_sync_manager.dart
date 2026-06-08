import 'package:flutter/foundation.dart';
import 'package:bradpos/data/data_sources/category_local_data_source.dart';
import 'package:bradpos/data/data_sources/category_remote_data_source.dart';
import 'package:bradpos/core/sync/sync_utils.dart';

class CategorySyncManager {
  final CategoryLocalDataSource localDataSource;
  final CategoryRemoteDataSource remoteDataSource;

  CategorySyncManager({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<void> push(String userId) async {
    final unsynced = await localDataSource.getUnsyncedCategories();
    if (unsynced.isEmpty) return;

    debugPrint(
      "CategorySync: Menemukan ${unsynced.length} kategori yang perlu push",
    );

    for (var catMap in unsynced) {
      try {
        var current = Map<String, dynamic>.from(catMap);
        final id = current['id'] as String;
        final name = current['name'] as String? ?? 'Tanpa Nama';
        final status = current['sync_status'] as String?;
        final ownerId = current['owner_id'] as String?;

        if (ownerId == null || status == null) continue;
        if (SyncUtils.belongsToOtherUser(ownerId, userId)) {
          debugPrint("CategorySync: Skip push '$name' (milik $ownerId, bukan $userId)");
          continue;
        }

        if (SyncUtils.isInvalidUuid(id)) {
          final (oldId, newId) = SyncUtils.fixUuid(id);
          debugPrint("CategorySync: Fix ID non-UUID '$oldId' ($name) -> $newId");
          await localDataSource.fixInvalidCategoryId(oldId, newId);
          current['id'] = newId;
        }

        if (SyncUtils.isGuestOwner(ownerId)) {
          current['owner_id'] = userId;
        }

        if (SyncUtils.shouldPush(status)) {
          debugPrint("CategorySync: Push ($status) kategori '$name' (${current['id']})");
          await remoteDataSource.pushCreatedCategory(current);
          await localDataSource.updateSyncStatus(current['id'], 'synced');
        }
      } catch (e) {
        debugPrint("CategorySync Push Error (${catMap['id']}): $e");
      }
    }
  }

  Future<void> pull(String userId) async {
    final lastSync = await localDataSource.getLastSyncTime(userId);
    debugPrint("CategorySync: Pulling categories from server (Last Sync: $lastSync)...");

    final remote = await remoteDataSource.getCategories(
      userId,
      lastSync: lastSync,
    );

    if (remote.isEmpty) {
      debugPrint("CategorySync: Tidak ada kategori baru di server.");
      return;
    }

    debugPrint("CategorySync: Berhasil menarik ${remote.length} kategori");
    await localDataSource.saveCategories(remote);
  }
}
