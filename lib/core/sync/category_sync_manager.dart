import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:bradpos/data/data_sources/category_local_data_source.dart';
import 'package:bradpos/data/data_sources/category_remote_data_source.dart';

class CategorySyncManager {
  final CategoryLocalDataSource localDataSource;
  final CategoryRemoteDataSource remoteDataSource;

  CategorySyncManager({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<void> push(String userId) async {
    try {
      final unsynced = await localDataSource.getUnsyncedCategories();
      if (unsynced.isEmpty) return;

      debugPrint(
        "CategorySync: Menemukan ${unsynced.length} kategori yang perlu push",
      );

      for (var catMap in unsynced) {
        try {
          var current = Map<String, dynamic>.from(catMap);
          String id = current['id'] as String;
          final name = current['name'] as String? ?? 'Tanpa Nama';
          final status = current['sync_status'] as String?;
          final ownerId = current['owner_id'] as String?;

          if (status == null) continue;

          // UUID Fix
          if (id.isEmpty || id.length != 36 || !id.contains('-')) {
            final oldId = id;
            final newUuid = const Uuid().v4();
            debugPrint(
              "CategorySync: Fix ID non-UUID '$oldId' ($name) -> $newUuid",
            );
            await localDataSource.fixInvalidCategoryId(oldId, newUuid);
            current['id'] = newUuid;
            id = newUuid;
          }

          if (ownerId == 'offline_guest' ||
              ownerId == null ||
              ownerId.isEmpty) {
            current['owner_id'] = userId;
          }

          if (status == 'created' ||
              status == 'pending_update' ||
              status == 'updated') {
            debugPrint("CategorySync: Push ($status) kategori '$name' ($id)");
            await remoteDataSource.pushCreatedCategory(current);
            await localDataSource.updateSyncStatus(id, 'synced');
          }
        } catch (e) {
          debugPrint("CategorySync Push Error (${catMap['id']}): $e");
        }
      }
    } catch (e) {
      debugPrint("CategorySync Push Failed: $e");
    }
  }

  Future<void> pull(String userId) async {
    try {
      final lastSync = await localDataSource.getLastSyncTime(userId);
      debugPrint(
        "CategorySync: Pulling categories from server (Last Sync: $lastSync)...",
      );

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
    } catch (e) {
      debugPrint("CategorySync Pull Failed: $e");
    }
  }
}
