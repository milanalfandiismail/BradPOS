import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bradpos/domain/entities/user_entity.dart';
import 'package:bradpos/core/sync/sync_utils.dart';
import 'package:bradpos/data/data_sources/profile_local_data_source.dart';

mixin KaryawanAuthMixin {
  SupabaseClient get supabase;
  SharedPreferences get prefs;
  ProfileLocalDataSource get profileLocalDataSource;

  Future<void> _saveLocalProfile(UserEntity user) async {
    await profileLocalDataSource.saveProfile({
      'id': user.id,
      'shop_name': user.shopName,
      'shop_id': user.shopId,
      'full_name': user.name,
      'remote_image': user.remoteImage,
      'local_image': user.localImage,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Either<String, UserEntity>> signInAsKaryawan(
    String shopId,
    String name,
    String password,
  ) async {
    try {
      final response = await supabase.rpc(
        'verify_karyawan_login_v2',
        params: {
          'p_shop_id': shopId,
          'p_full_name': name,
          'p_password': SyncUtils.hashPassword(password)
        },
      );

      if (response == null || (response as List).isEmpty) {
        return const Left('Shop ID, Nama, atau password salah');
      }

      final karyawanData = response[0];

      String shopName = 'BradPOS';
      String? dbShopId;
      try {
        final ownerProfile = await supabase
            .from('profiles')
            .select('shop_name, shop_id')
            .eq('id', karyawanData['owner_id'])
            .single();
        shopName = ownerProfile['shop_name'] ?? 'BradPOS';
        dbShopId = ownerProfile['shop_id'];
      } catch (_) {}

      final user = UserEntity(
        id: karyawanData['id'],
        email: '', // No email for employee
        name: karyawanData['full_name'],
        shopName: shopName,
        shopId: dbShopId ?? shopId,
        role: 'karyawan',
        ownerId: karyawanData['owner_id'],
        remoteImage: karyawanData['remote_image'],
        localImage: karyawanData['local_image'],
      );

      await _saveLocalProfile(user);
      await prefs.setString('karyawan_session', jsonEncode(user.toMap()));

      return Right(user);
    } catch (e) {
      return Left('Gagal login: ${e.toString()}');
    }
  }

  Future<Either<String, String>> createKaryawan(
    String fullName,
    String password,
  ) async {
    try {
      final response = await supabase.rpc(
        'create_karyawan_v2',
        params: {
          'p_full_name': fullName,
          'p_password': SyncUtils.hashPassword(password),
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
}
