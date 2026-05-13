import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bradpos/domain/entities/user_entity.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/data/data_sources/profile_local_data_source.dart';
import 'package:bradpos/core/sync/sync_utils.dart';
import 'package:bradpos/data/data_sources/profile_remote_data_source.dart';
import 'package:bradpos/data/repositories/auth_karyawan_repository_impl.dart';

class AuthRepositoryImpl with KaryawanAuthMixin implements AuthRepository {
  @override
  final SupabaseClient supabase;
  @override
  final SharedPreferences prefs;
  @override
  final ProfileLocalDataSource profileLocalDataSource;
  final ProfileRemoteDataSource profileRemoteDataSource;

  static const String _karyawanSessionKey = 'karyawan_session';
  static const String _ownerSessionKey = 'owner_session';
  static const String _guestSessionKey = 'guest_session';

  AuthRepositoryImpl({
    required this.supabase,
    required this.prefs,
    required this.profileLocalDataSource,
    required this.profileRemoteDataSource,
  });

  // ==================== OWNER AUTH (Supabase Auth) ====================

  @override
  Future<Either<String, UserEntity>> signIn(
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        // Fetch profile immediately
        final profile = await profileRemoteDataSource.getProfile(
          user.id,
          isStaff: false,
        );

        final userEntity = UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: profile?['full_name'] ?? user.userMetadata?['full_name'],
          shopName:
              profile?['shop_name'] ??
              user.userMetadata?['shop_name'] ??
              'BradPOS',
          shopId: profile?['shop_id'] ?? user.userMetadata?['shop_id'],
          role: 'owner',
          remoteImage: profile?['remote_image'],
          address: profile?['address'],
          phone: profile?['phone'],
        );

        await _saveLocalProfile(userEntity);
        await prefs.setString(_ownerSessionKey, jsonEncode(userEntity.toMap()));
        return Right(userEntity);
      }
      return const Left('Terjadi kesalahan yang tidak diketahui');
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'shop_name': 'BradPOS'},
      );
      final user = response.user;
      if (user != null) {
        // Fetch profile (might be empty but good for consistency)
        final profile = await profileRemoteDataSource.getProfile(
          user.id,
          isStaff: false,
        );

        final userEntity = UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: fullName,
          shopName: profile?['shop_name'] ?? 'BradPOS',
          shopId: profile?['shop_id'],
          role: 'owner',
          remoteImage: profile?['remote_image'],
        );
        await _saveLocalProfile(userEntity);
        await prefs.setString(_ownerSessionKey, jsonEncode(userEntity.toMap()));
        return Right(userEntity);
      }
      return const Left('Terjadi kesalahan saat registrasi');
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.toString(),
        );
        return const Left('Mengalihkan ke halaman login Google...');
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return const Left('Gagal mendapatkan ID Token dari Google');
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final user = response.user;
      if (user != null) {
        final profile = await profileRemoteDataSource.getProfile(
          user.id,
          isStaff: false,
        );

        final userEntity = UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: profile?['full_name'] ?? user.userMetadata?['full_name'],
          shopName:
              profile?['shop_name'] ??
              user.userMetadata?['shop_name'] ??
              'BradPOS',
          shopId: profile?['shop_id'] ?? user.userMetadata?['shop_id'],
          role: 'owner',
          remoteImage: profile?['remote_image'],
          address: profile?['address'],
          phone: profile?['phone'],
        );
        await _saveLocalProfile(userEntity);
        await prefs.setString(_ownerSessionKey, jsonEncode(userEntity.toMap()));
        return Right(userEntity);
      }

      return const Left('Gagal menyinkronkan akun dengan Supabase');
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    try {
      await supabase.auth.signOut();
      await prefs.remove(_karyawanSessionKey);
      await prefs.remove(_ownerSessionKey);
      await prefs.remove(_guestSessionKey);

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    try {
      if (prefs.containsKey('local_shop_name')) {
        await prefs.remove('local_shop_name');
      }

      // 1. Cek Sesi Owner di Prefs
      final ownerJson = prefs.getString(_ownerSessionKey);
      if (ownerJson != null) {
        final ownerMap = jsonDecode(ownerJson);
        final profile = await profileLocalDataSource.getProfile(ownerMap['id']);
        final shopName =
            profile?['shop_name'] ?? ownerMap['shop_name'] ?? 'BradPOS';
        final shopId = profile?['shop_id'] ?? ownerMap['shop_id'];
        final remoteImage =
            profile?['remote_image'] ?? ownerMap['remote_image'];
        final localImage = profile?['local_image'] ?? ownerMap['local_image'];

        return Right(
          UserEntity.fromMap({
            ...ownerMap,
            'shop_name': shopName,
            'shop_id': shopId,
            'remote_image': remoteImage,
            'local_image': localImage,
          }),
        );
      }

      // 2. Cek Sesi Owner di SDK
      final sbUser = supabase.auth.currentUser;
      if (sbUser != null) {
        final profile = await profileLocalDataSource.getProfile(sbUser.id);
        final fullName =
            profile?['full_name'] ?? sbUser.userMetadata?['full_name'];
        final shopName =
            profile?['shop_name'] ??
            sbUser.userMetadata?['shop_name'] ??
            'BradPOS';
        final shopId = profile?['shop_id'] ?? sbUser.userMetadata?['shop_id'];
        final remoteImage =
            profile?['remote_image'] ?? sbUser.userMetadata?['remote_image'];
        final localImage =
            profile?['local_image'] ?? sbUser.userMetadata?['local_image'];

        final userEntity = UserEntity(
          id: sbUser.id,
          email: sbUser.email ?? '',
          name: fullName,
          shopName: shopName,
          shopId: shopId,
          role: 'owner',
          remoteImage: remoteImage,
          localImage: localImage,
        );
        await prefs.setString(_ownerSessionKey, jsonEncode(userEntity.toMap()));
        return Right(userEntity);
      }

      // 3. Cek Sesi Karyawan
      final karyawanJson = prefs.getString(_karyawanSessionKey);
      if (karyawanJson != null) {
        final karyawanMap = jsonDecode(karyawanJson);
        final ownerProfile = await profileLocalDataSource.getProfile(
          karyawanMap['owner_id'] ?? '',
        );
        final personalProfile = await profileLocalDataSource.getProfile(
          karyawanMap['id'] ?? '',
        );

        final shopName = ownerProfile?['shop_name'] ?? 'BradPOS';
        final shopId = ownerProfile?['shop_id'];

        return Right(
          UserEntity.fromMap({
            ...karyawanMap,
            'shop_name': shopName,
            'shop_id': shopId,
            'remote_image':
                personalProfile?['remote_image'] ?? karyawanMap['remote_image'],
            'local_image':
                personalProfile?['local_image'] ?? karyawanMap['local_image'],
            'name': personalProfile?['full_name'] ?? karyawanMap['name'],
          }),
        );
      }

      // 4. Cek Mode Guest
      if (isGuestMode()) {
        final profile = await profileLocalDataSource.getProfile(
          'offline_guest',
        );
        final shopName = profile?['shop_name'] ?? 'BradPOS';
        return Right(
          UserEntity(
            id: 'offline_guest',
            email: 'guest@offline.local',
            name: 'Guest (Offline)',
            shopName: shopName,
            role: 'guest',
          ),
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> updateProfile({
    String? fullName,
    String? shopName,
    String? shopId,
    String? remoteImage,
    String? localImage,
    String? address,
    String? phone,
    String? newPassword,
  }) async {
    try {
      final userResult = await getCurrentUser();
      final user = userResult.getOrElse(() => null);
      if (user == null) return const Left('Sesi tidak ditemukan');

      String? finalRemoteUrl = remoteImage ?? user.remoteImage;

      if (localImage != null && !localImage.startsWith('http')) {
        if (user.remoteImage != null) {
          await profileRemoteDataSource.deleteProfileImage(user.remoteImage!);
        }
        finalRemoteUrl = await profileRemoteDataSource.uploadProfileImage(
          localImage,
          user.id,
          isStaff: user.role == 'karyawan',
        );
      }

      final updatedUser = UserEntity(
        id: user.id,
        email: user.email,
        name: fullName ?? user.name,
        shopName: shopName ?? user.shopName,
        shopId: shopId ?? user.shopId,
        role: user.role,
        ownerId: user.ownerId,
        remoteImage: finalRemoteUrl ?? user.remoteImage,
        localImage: localImage ?? user.localImage,
        address: address ?? user.address,
        phone: phone ?? user.phone,
      );

      // Handle Password Change
      if (newPassword != null && newPassword.isNotEmpty) {
        if (user.role == 'karyawan') {
          final hashedPassword = SyncUtils.hashPassword(newPassword);
          await supabase
              .from('karyawan')
              .update({'password_hash': hashedPassword})
              .eq('id', user.id);
        } else if (user.role == 'owner') {
          await supabase.auth.updateUser(UserAttributes(password: newPassword));
        }
      }

      // Sync Karyawan Table if info changes
      if (user.role == 'karyawan') {
        final Map<String, dynamic> updateKaryawan = {};
        if (fullName != null) {
          updateKaryawan['full_name'] = fullName;
        }
        if (finalRemoteUrl != null) {
          updateKaryawan['remote_image'] = finalRemoteUrl;
        }
        if (localImage != null) {
          updateKaryawan['local_image'] = localImage;
        }

        if (updateKaryawan.isNotEmpty) {
          await supabase
              .from('karyawan')
              .update(updateKaryawan)
              .eq('id', user.id);
        }
      }

      await _saveLocalProfile(updatedUser);
      if (user.role == 'karyawan') {
        await prefs.setString(
          _karyawanSessionKey,
          jsonEncode(updatedUser.toMap()),
        );
      } else {
        await prefs.setString(
          _ownerSessionKey,
          jsonEncode(updatedUser.toMap()),
        );
      }

      if (user.role == 'owner') {
        final Map<String, dynamic> updateData = {
          'id': user.id,
          'updated_at': SyncUtils.formatWebDate(DateTime.now()),
        };
        if (fullName != null) updateData['full_name'] = fullName;
        if (shopName != null) updateData['shop_name'] = shopName;
        if (shopId != null) updateData['shop_id'] = shopId;
        if (address != null) updateData['address'] = address;
        if (phone != null) updateData['phone'] = phone;
        if (finalRemoteUrl != null) updateData['remote_image'] = finalRemoteUrl;
        if (localImage != null) updateData['local_image'] = localImage;

        try {
          await profileRemoteDataSource.upsertProfile(updateData);
        } catch (e) {
          debugPrint("AuthRepository: Remote profile update failed: $e");
          // Kita lanjut saja karena local sudah sukses
        }

        if (shopName != null && user.role == 'owner') {
          await supabase.auth.updateUser(
            UserAttributes(data: {'shop_name': shopName}),
          );
        }
      }

      return Right(updatedUser);
    } catch (e) {
      debugPrint("AuthRepository: Error updateProfile: $e");
      return Left(e.toString());
    }
  }

  // ==================== Guest AUTH (Offline Mode) ====================

  @override
  Future<Either<String, UserEntity>> signInAsGuest() async {
    try {
      await prefs.setBool(_guestSessionKey, true);
      final profile = await profileLocalDataSource.getProfile('offline_guest');
      final shopName = profile?['shop_name'] ?? 'BradPOS';
      final userEntity = UserEntity(
        id: 'offline_guest',
        email: 'guest@offline.local',
        name: 'Guest (Offline)',
        shopName: shopName,
        role: 'guest',
        remoteImage: profile?['remote_image'],
        localImage: profile?['local_image'],
      );
      return Right(userEntity);
    } catch (e) {
      return Left('Gagal masuk sebagai guest: ${e.toString()}');
    }
  }

  @override
  bool isGuestMode() {
    return prefs.getBool(_guestSessionKey) ?? false;
  }

  Future<void> _saveLocalProfile(UserEntity user) async {
    await profileLocalDataSource.saveProfile({
      'id': user.id,
      'shop_name': user.shopName,
      'shop_id': user.shopId,
      'full_name': user.name,
      'remote_image': user.remoteImage,
      'local_image': user.localImage,
      'updated_at': SyncUtils.formatWebDate(DateTime.now()),
    });
  }
}
