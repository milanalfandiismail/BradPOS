import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';

import 'package:flutter/foundation.dart';

/// Shared helpers for sync managers and repositories.
class SyncUtils {
  static const _uuid = Uuid();
  static const String offlineGuest = 'offline_guest';

  /// Consistent ISO8601 for Web (fixed 3ms precision)
  static String formatWebDate(DateTime dt) {
    if (!kIsWeb) return dt.toIso8601String();
    return '${dt.toIso8601String().split('.').first}.${dt.millisecond.toString().padLeft(3, '0')}';
  }

  /// Returns true if [id] is NOT a valid UUID v4.
  static bool isInvalidUuid(String id) =>
      id.isEmpty || id.length != 36 || !id.contains('-');

  /// Replace non-UUID [oldId] with fresh UUID v4.
  /// Returns [newId, newUuid].
  static (String oldId, String newId) fixUuid(String oldId) =>
      (oldId, _uuid.v4());

  /// Should we skip this record because [ownerId] doesn't match [userId]?
  static bool belongsToOtherUser(String ownerId, String userId) =>
      ownerId != userId;

  /// Should we reassign [offlineGuest] / empty owner to [userId]?
  static bool isGuestOwner(String? ownerId) =>
      ownerId == null || ownerId == offlineGuest || ownerId.isEmpty;

  /// Map of `sync_status` values that should be pushed to server.
  static bool shouldPush(String status) =>
      status == 'created' ||
      status == 'updated' ||
      status == 'pending_update';

  /// SHA-256 hash.
  static String hashPassword(String password) {
    final digest = sha256.convert(utf8.encode(password));
    return digest.toString();
  }

  /// Resolve effective user ID from [AuthRepository].
  /// Returns [offlineGuest] on failure or null user.
  static Future<String> getUserId(AuthRepository authRepository) async {
    final userResult = await authRepository.getCurrentUser();
    return userResult.fold(
      (_) => offlineGuest,
      (user) {
        if (user == null) return offlineGuest;
        if (user.role == 'karyawan' && user.ownerId != null) return user.ownerId!;
        return user.id;
      },
    );
  }
}
