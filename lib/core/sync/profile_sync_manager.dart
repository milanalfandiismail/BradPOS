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
      final localProfile = await localDataSource.getProfile(effectiveUserId);
      final localUpdatedAt = localProfile?['updated_at'] as String?;

      final response = await remoteDataSource.getProfile(
        effectiveUserId,
        localUpdatedAt: localUpdatedAt,
      );

      if (response == null) {
        debugPrint("ProfileSync: Profile sudah up-to-date atau tidak ditemukan.");
        return;
      }

      final newShopName = response['shop_name'] as String?;
      final newShopId = response['shop_id'] as String?;
      final newFullName = response['full_name'] as String?;
      final newAddress = response['address'] as String?;
      final newPhone = response['phone'] as String?;
      final newRemoteImg = response['remote_image'] as String?;
      final newLocalImg = response['local_image'] as String?;

      bool isChanged =
          newShopName != user.shopName ||
          newShopId != user.shopId ||
          newFullName != user.name ||
          newAddress != user.address ||
          newPhone != user.phone ||
          newRemoteImg != user.remoteImage ||
          newLocalImg != user.localImage;

      if (!isChanged) {
        debugPrint("ProfileSync: Profil sudah up-to-date.");
        return;
      }

      debugPrint("ProfileSync: Menemukan perubahan data dari server. Update lokal...");

      final updatedUser = UserEntity(
        id: user.id,
        email: user.email,
        name: newFullName ?? user.name,
        shopName: newShopName ?? user.shopName,
        shopId: (newShopId != null && newShopId.isNotEmpty) ? newShopId : user.shopId,
        role: user.role,
        ownerId: user.ownerId,
        remoteImage: newRemoteImg,
        localImage: newLocalImg,
        address: newAddress,
        phone: newPhone,
      );

      await localDataSource.saveProfile({
        'id': effectiveUserId,
        'shop_name': updatedUser.shopName,
        'shop_id': updatedUser.shopId,
        'full_name': updatedUser.name,
        'remote_image': updatedUser.remoteImage,
        'local_image': updatedUser.localImage,
        'updated_at': response['updated_at'] as String?,
      });

      if (user.role == 'owner') {
        await prefs.setString(
          _ownerSessionKey,
          jsonEncode(updatedUser.toMap()),
        );
      } else if (user.role == 'karyawan') {
        final karyawanJson = prefs.getString(_karyawanSessionKey);
        if (karyawanJson != null) {
          final karyawanMap = jsonDecode(karyawanJson);
          karyawanMap['shop_name'] = newShopName;
          await prefs.setString(_karyawanSessionKey, jsonEncode(karyawanMap));
        }
      }

      debugPrint("ProfileSync: Berhasil sinkronisasi profil.");
    } catch (e) {
      debugPrint("ProfileSync Error: $e");
    }
  }
}
