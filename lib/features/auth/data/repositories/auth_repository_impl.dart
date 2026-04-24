import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabase;
  final SharedPreferences prefs;

  static const String _karyawanSessionKey = 'karyawan_session';

  AuthRepositoryImpl({
    required this.supabase,
    required this.prefs,
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
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
            role: 'owner',
          ),
        );
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
        data: {'full_name': fullName},
      );
      final user = response.user;
      if (user != null) {
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
            role: 'owner',
          ),
        );
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
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
            role: 'owner',
          ),
        );
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
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    try {
      // 1. Cek Sesi Supabase (Owner)
      final user = supabase.auth.currentUser;
      if (user != null) {
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
            role: 'owner',
          ),
        );
      }

      // 2. Cek Sesi Lokal (Karyawan)
      final karyawanJson = prefs.getString(_karyawanSessionKey);
      if (karyawanJson != null) {
        final karyawanMap = jsonDecode(karyawanJson);
        return Right(UserEntity.fromMap(karyawanMap));
      }

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  // ==================== Karyawan AUTH (Custom Database) ====================

  @override
  Future<Either<String, UserEntity>> signInAsKaryawan(
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.rpc('verify_karyawan_login', params: {
        'p_email': email,
        'p_password': password,
      });

      if (response == null || (response as List).isEmpty) {
        return const Left('Email atau password karyawan salah');
      }

      final karyawanData = response[0];
      final user = UserEntity(
        id: karyawanData['id'],
        email: karyawanData['email'],
        name: karyawanData['full_name'],
        role: 'karyawan',
        ownerId: karyawanData['owner_id'],
      );

      // Simpan sesi ke lokal
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
      final response = await supabase.rpc('create_karyawan', params: {
        'p_full_name': fullName,
        'p_email': email,
        'p_password': password,
      });

      return Right(response.toString());
    } catch (e) {
      if (e.toString().contains('duplicate')) {
        return const Left('Email karyawan sudah terdaftar');
      }
      return Left('Gagal membuat akun karyawan: ${e.toString()}');
    }
  }
}
