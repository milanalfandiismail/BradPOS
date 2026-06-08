import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bradpos/data/data_sources/profile_local_data_source.dart';
import 'package:bradpos/data/data_sources/profile_remote_data_source.dart';
import 'package:bradpos/domain/entities/user_entity.dart';

class ProfileSyncManager {
  final ProfileLocalDataSource localDataSource;
  final ProfileRemoteDataSource remoteDataSource;
  final SharedPreferences prefs;

  static const String _ownerSessionKey = 'owner_session';
  static const String _karyawanSessionKey = 'karyawan_session';

  ProfileSyncManager({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.prefs,
  });

  Future<void> sync(UserEntity user) async {
    if (user.role == 'guest') return;

    final String effectiveUserId =
        (user.role == 'karyawan' && user.ownerId != null)
            ? user.ownerId!
            : user.id;

    debugPrint(
      "ProfileSync: Sinkronisasi profil untuk $effectiveUserId (Role: ${user.role})",
    );

    try {
      final bool isStaff = user.role == 'karyawan';
      
      // 1. Get Core Profile Data (Identity for Owner, Shop for Staff)
      final localProfile = await localDataSource.getProfile(effectiveUserId);
      final localUpdatedAt = localProfile?['updated_at'] as String?;

      final coreResponse = await remoteDataSource.getProfile(
        effectiveUserId,
        localUpdatedAt: localUpdatedAt,
        isStaff: false, // Profiles table
      );

      // 2. If Staff, also get Personal Identity Data
      Map<String, dynamic>? staffResponse;
      if (isStaff) {
        staffResponse = await remoteDataSource.getProfile(
          user.id,
          isStaff: true, // Karyawan table
        );
      }

      if (coreResponse == null && staffResponse == null) {
        debugPrint("ProfileSync: Profile sudah up-to-date.");
        return;
      }

      // Merge data
      final newShopName = coreResponse?['shop_name'] as String?;
      final newShopId = coreResponse?['shop_id'] as String?;
      final newAddress = coreResponse?['address'] as String?;
      final newPhone = coreResponse?['phone'] as String?;
      
      final newFullName = (isStaff ? (staffResponse?['full_name']) : (coreResponse?['full_name'])) as String?;
      final newRemoteImg = (isStaff ? (staffResponse?['remote_image']) : (coreResponse?['remote_image'])) as String?;
      final newLocalImg = (isStaff ? (staffResponse?['local_image']) : (coreResponse?['local_image'])) as String?;

      bool isChanged =
          (newShopName != null && newShopName != user.shopName) ||
          (newShopId != null && newShopId != user.shopId) ||
          (newFullName != null && newFullName != user.name) ||
          (newAddress != null && newAddress != user.address) ||
          (newPhone != null && newPhone != user.phone) ||
          (newRemoteImg != null && newRemoteImg != user.remoteImage) ||
          (newLocalImg != null && newLocalImg != user.localImage);

      if (!isChanged) {
        debugPrint("ProfileSync: Tidak ada perubahan profil.");
        return;
      }

      debugPrint("ProfileSync: Menemukan perubahan data. Update lokal...");

      final updatedUser = UserEntity(
        id: user.id,
        email: user.email,
        name: newFullName ?? user.name,
        shopName: newShopName ?? user.shopName,
        shopId: (newShopId != null && newShopId.isNotEmpty) ? newShopId : user.shopId,
        role: user.role,
        ownerId: user.ownerId,
        remoteImage: newRemoteImg ?? user.remoteImage,
        localImage: newLocalImg ?? user.localImage,
        address: newAddress ?? user.address,
        phone: newPhone ?? user.phone,
      );

      await localDataSource.saveProfile({
        'id': isStaff ? user.id : effectiveUserId,
        'shop_name': updatedUser.shopName,
        'shop_id': updatedUser.shopId,
        'full_name': updatedUser.name,
        'remote_image': updatedUser.remoteImage,
        'local_image': updatedUser.localImage,
        'updated_at': coreResponse?['updated_at'] ?? DateTime.now().toIso8601String(),
      });

      if (user.role == 'owner') {
        await prefs.setString(_ownerSessionKey, jsonEncode(updatedUser.toMap()));
      } else if (user.role == 'karyawan') {
        await prefs.setString(_karyawanSessionKey, jsonEncode(updatedUser.toMap()));
      }

      debugPrint("ProfileSync: Berhasil sinkronisasi profil.");
    } catch (e) {
      debugPrint("ProfileSync Error: $e");
    }
  }
}
