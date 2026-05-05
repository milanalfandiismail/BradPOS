import 'package:flutter/foundation.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/core/sync/category_sync_manager.dart';
import 'package:bradpos/core/sync/product_sync_manager.dart';
import 'package:bradpos/core/sync/transaction_sync_manager.dart';
import 'package:bradpos/core/sync/profile_sync_manager.dart';
import 'package:bradpos/domain/entities/user_entity.dart';

class SyncService {
  final AuthRepository authRepository;
  final CategorySyncManager categorySync;
  final ProductSyncManager productSync;
  final TransactionSyncManager transactionSync;
  final ProfileSyncManager profileSync;

  bool _isSyncing = false;

  SyncService({
    required this.authRepository,
    required this.categorySync,
    required this.productSync,
    required this.transactionSync,
    required this.profileSync,
  });

  Future<void> syncAll({UserEntity? user, int? limit, int? offset}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    final activeUser = user ?? (await authRepository.getCurrentUser()).getOrElse(() => null);

    if (activeUser == null) {
      debugPrint("SyncService: Skip sync karena user belum login atau sesi hilang");
      _isSyncing = false;
      return;
    }

    final String effectiveUserId = (activeUser.isKaryawan && activeUser.ownerId != null)
        ? activeUser.ownerId!
        : activeUser.id;

    try {
      debugPrint("SyncService: Memulai sinkronisasi modular untuk user $effectiveUserId");

      // 1. Profile Sync
      try {
        await profileSync.sync(activeUser);
      } catch (e) {
        debugPrint("SyncService: ProfileSync failed: $e");
      }

      // 2. PUSH PHASE
      debugPrint("SyncService: Memulai Push Phase...");
      try { await categorySync.push(effectiveUserId); } catch (e) { debugPrint("SyncService: CategoryPush failed: $e"); }
      try { await productSync.push(effectiveUserId); } catch (e) { debugPrint("SyncService: ProductPush failed: $e"); }
      try { await transactionSync.push(effectiveUserId); } catch (e) { debugPrint("SyncService: TransactionPush failed: $e"); }

      // 3. PULL PHASE
      debugPrint("SyncService: Memulai Pull Phase...");
      try { await productSync.pull(effectiveUserId, limit: limit, offset: offset); } catch (e) { debugPrint("SyncService: ProductPull failed: $e"); }
      try { await transactionSync.pull(effectiveUserId); } catch (e) { debugPrint("SyncService: TransactionPull failed: $e"); }
      try { await categorySync.pull(effectiveUserId); } catch (e) { debugPrint("SyncService: CategoryPull failed: $e"); }

      debugPrint("SyncService: Sinkronisasi modular selesai");
    } catch (e) {
      debugPrint("SyncService Error Fatal: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
