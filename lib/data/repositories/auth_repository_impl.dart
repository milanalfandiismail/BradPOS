import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bradpos/domain/entities/user_entity.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/data/data_sources/profile_local_data_source.dart';
import 'package:bradpos/data/data_sources/profile_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabase;
  final SharedPreferences prefs;
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
        final shopName = user.userMetadata?['shop_name'] ?? 'BradPOS';
        final userEntity = UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['full_name'],
          shopName: shopName,
          role: 'owner',
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
        data: {
          'full_name': fullName,
          'shop_name': 'BradPOS',
        },
      );
      final user = response.user;
      if (user != null) {
        final userEntity = UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['full_name'],
          shopName: 'BradPOS',
          role: 'owner',
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
        final shopName = user.userMetadata?['shop_name'] ?? 'BradPOS';
        final userEntity = UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['full_name'],
          shopName: shopName,
          role: 'owner',
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
        final remoteImage =
            profile?['remote_image'] ?? ownerMap['remote_image'];
        final localImage = profile?['local_image'] ?? ownerMap['local_image'];

        return Right(
          UserEntity.fromMap({
            ...ownerMap,
            'shop_name': shopName,
            'remote_image': remoteImage,
            'local_image': localImage,
          }),
        );
      }

      // 2. Cek Sesi Owner di SDK
      final sbUser = supabase.auth.currentUser;
      if (sbUser != null) {
        final profile = await profileLocalDataSource.getProfile(sbUser.id);
        final shopName =
            profile?['shop_name'] ??
            sbUser.userMetadata?['shop_name'] ??
            'BradPOS';
        final remoteImage =
            profile?['remote_image'] ?? sbUser.userMetadata?['remote_image'];
        final localImage =
            profile?['local_image'] ?? sbUser.userMetadata?['local_image'];

        final userEntity = UserEntity(
          id: sbUser.id,
          email: sbUser.email ?? '',
          name: sbUser.userMetadata?['full_name'],
          shopName: shopName,
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
        final profile = await profileLocalDataSource.getProfile(karyawanMap['owner_id'] ?? '');
        final shopName = profile?['shop_name'] ?? 'BradPOS';
        return Right(
          UserEntity.fromMap({...karyawanMap, 'shop_name': shopName}),
        );
      }

      // 4. Cek Mode Guest
      if (isGuestMode()) {
        final profile = await profileLocalDataSource.getProfile('offline_guest');
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
    String? shopName,
    String? remoteImage,
    String? localImage,
    String? address,
    String? phone,
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
        finalRemoteUrl = await profileRemoteDataSource.uploadProfileImage(localImage, user.id);
      }

      final updatedUser = UserEntity(
        id: user.id,
        email: user.email,
        name: user.name,
        shopName: shopName ?? user.shopName,
        role: user.role,
        ownerId: user.ownerId,
        remoteImage: finalRemoteUrl ?? user.remoteImage,
        localImage: localImage ?? user.localImage,
        address: address ?? user.address,
        phone: phone ?? user.phone,
      );

      await _saveLocalProfile(updatedUser);
      await prefs.setString(_ownerSessionKey, jsonEncode(updatedUser.toMap()));

      if (user.role != 'guest') {
        final Map<String, dynamic> updateData = {
          'id': user.id,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (shopName != null) updateData['shop_name'] = shopName;
        if (address != null) updateData['address'] = address;
        if (phone != null) updateData['phone'] = phone;
        if (finalRemoteUrl != null) updateData['remote_image'] = finalRemoteUrl;
        if (localImage != null) updateData['local_image'] = localImage;

        await profileRemoteDataSource.upsertProfile(updateData);

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

  @override
  Future<void> syncProfile() async {
    // Profile sync moved to ProfileSyncManager.
    // Method kept for backward compatibility with AuthRepository interface.
    // SyncService now uses ProfileSyncManager directly.
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

  // ==================== Karyawan AUTH (Custom Database) ====================

  @override
  Future<Either<String, UserEntity>> signInAsKaryawan(
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.rpc(
        'verify_karyawan_login',
        params: {'p_email': email, 'p_password': password},
      );

      if (response == null || (response as List).isEmpty) {
        return const Left('Email atau password karyawan salah');
      }

      final karyawanData = response[0];

      String shopName = 'BradPOS';
      try {
        final ownerProfile = await supabase
            .from('profiles')
            .select('shop_name')
            .eq('id', karyawanData['owner_id'])
            .single();
        shopName = ownerProfile['shop_name'] ?? 'BradPOS';
      } catch (_) {}

      final user = UserEntity(
        id: karyawanData['id'],
        email: karyawanData['email'],
        name: karyawanData['full_name'],
        shopName: shopName,
        role: 'karyawan',
        ownerId: karyawanData['owner_id'],
      );

      await _saveLocalProfile(user);
      await prefs.setString(_karyawanSessionKey, jsonEncode(user.toMap()));

      return Right(user);
    } catch (e) {
      return Left('Gagal login: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, String>> createKaryawan(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.rpc(
        'create_karyawan',
        params: {
          'p_full_name': fullName,
          'p_email': email,
          'p_password': password,
        },
      );
      return Right(response.toString());
    } catch (e) {
      if (e.toString().contains('duplicate')) {
        return const Left('Email karyawan sudah terdaftar');
      }
      return Left('Gagal membuat akun karyawan: ${e.toString()}');
    }
  }

  Future<void> _saveLocalProfile(UserEntity user) async {
    await profileLocalDataSource.saveProfile({
      'id': user.role == 'karyawan' ? user.ownerId : user.id,
      'shop_name': user.shopName,
      'full_name': user.name,
      'remote_image': user.remoteImage,
      'local_image': user.localImage,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
