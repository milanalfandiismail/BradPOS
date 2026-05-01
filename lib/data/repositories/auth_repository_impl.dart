import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bradpos/core/database/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bradpos/domain/entities/user_entity.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';

/// Implementasi Autentikasi untuk BradPOS.
/// Mendukung dua jenis login: 
/// 1. Owner (via Supabase Auth Resmi)
/// 2. Karyawan (via Custom Table 'karyawan' di Database)
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabase;
  final SharedPreferences prefs;

  // Key untuk menyimpan sesi karyawan di penyimpanan lokal
  static const String _karyawanSessionKey = 'karyawan_session';
  static const String _guestSessionKey = 'guest_session';
  static const String _localShopNameKey = 'local_shop_name';

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
        final shopName = user.userMetadata?['shop_name'] ?? 'BradPOS';
        await prefs.setString(_localShopNameKey, shopName);
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
            shopName: shopName,
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
        data: {
          'full_name': fullName,
          'shop_name': 'BradPOS', // Default name
        },
      );
      final user = response.user;
      if (user != null) {
        await prefs.setString(_localShopNameKey, 'BradPOS');
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
            shopName: 'BradPOS',
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
        final shopName = user.userMetadata?['shop_name'] ?? 'BradPOS';
        await prefs.setString(_localShopNameKey, shopName);
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
            shopName: shopName,
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
      await prefs.remove(_guestSessionKey);
      await prefs.remove(_localShopNameKey);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    try {
      // 1. Cek Sesi Owner
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Ambil dari lokal dulu (offline-first), kalo gak ada ambil metadata
        String shopName = prefs.getString(_localShopNameKey) ?? user.userMetadata?['shop_name'] ?? 'BradPOS';
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
            shopName: shopName,
            role: 'owner',
          ),
        );
      }

      // 2. Cek Sesi Karyawan
      final karyawanJson = prefs.getString(_karyawanSessionKey);
      if (karyawanJson != null) {
        final karyawanMap = jsonDecode(karyawanJson);
        final shopName = prefs.getString(_localShopNameKey) ?? 'BradPOS';
        return Right(UserEntity.fromMap({...karyawanMap, 'shop_name': shopName}));
      }

      // 3. Cek Mode Guest
      if (isGuestMode()) {
        final shopName = prefs.getString(_localShopNameKey) ?? 'BradPOS';
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
  Future<Either<String, void>> updateShopName(String shopName) async {
    try {
      // 1. Update Lokal (Offline-First)
      await prefs.setString(_localShopNameKey, shopName);

      // 2. Update Remote (Cloud Sync) - Hanya jika user login (bukan guest)
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Update Auth Metadata
        await supabase.auth.updateUser(
          UserAttributes(
            data: {'shop_name': shopName},
          ),
        );

        // SYNC KE TABEL PROFILES REMOTE
        await supabase.from('profiles').upsert({
          'id': user.id,
          'shop_name': shopName,
          'updated_at': DateTime.now().toIso8601String(),
        });

        // SYNC KE TABEL PROFILES LOKAL (SQLite)
        final db = await DatabaseHelper.instance.database;
        await db.insert(
          'profiles',
          {
            'id': user.id,
            'shop_name': shopName,
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // Update sesi karyawan di lokal kalo dia yg update (opsional, biasanya owner yg update)
      if (user != null && user.role == 'karyawan') {
        final karyawanJson = prefs.getString(_karyawanSessionKey);
        if (karyawanJson != null) {
          final karyawanMap = jsonDecode(karyawanJson);
          karyawanMap['shop_name'] = shopName;
          await prefs.setString(_karyawanSessionKey, jsonEncode(karyawanMap));
        }
      }

      return const Right(null);
    } catch (e) {
      // Kita tetep return Right walaupun remote gagal (karena lokal sudah update)
      // Tapi baiknya kasih info kalo sync gagal
      return Left('Sync gagal, tapi lokal tersimpan: ${e.toString()}');
    }
  }

  @override
  Future<void> refreshShopName() async {
    try {
      final userResult = await getCurrentUser();
      final user = userResult.getOrElse(() => null);
      if (user == null || user.role == 'guest') return;

      final String effectiveUserId = (user.role == 'karyawan' && user.ownerId != null) 
          ? user.ownerId! 
          : user.id;

      debugPrint("AuthRepository: Refreshing shop name for $effectiveUserId (Role: ${user.role})");

      // Tarik dari tabel profiles
      final response = await supabase.from('profiles').select('shop_name').eq('id', effectiveUserId).maybeSingle();
      
      if (response == null) {
        debugPrint("AuthRepository: Profile tidak ditemukan di Supabase untuk ID: $effectiveUserId");
        return;
      }

      final newShopName = response['shop_name'] as String?;
      debugPrint("AuthRepository: Shop Name dari server -> $newShopName");
      
      if (newShopName != null && newShopName != user.shopName) {
        debugPrint("AuthRepository: Mengupdate nama toko lokal ke: $newShopName");
        await prefs.setString(_localShopNameKey, newShopName);
        
        // SYNC KE TABEL PROFILES LOKAL (SQLite)
        final db = await DatabaseHelper.instance.database;
        await db.insert(
          'profiles',
          {
            'id': effectiveUserId,
            'shop_name': newShopName,
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        // Jika karyawan, update juga session JSON-nya
        if (user.role == 'karyawan') {
          final karyawanJson = prefs.getString(_karyawanSessionKey);
          if (karyawanJson != null) {
            final karyawanMap = jsonDecode(karyawanJson);
            karyawanMap['shop_name'] = newShopName;
            await prefs.setString(_karyawanSessionKey, jsonEncode(karyawanMap));
          }
        }
      }
    } catch (e) {
      debugPrint("AuthRepository: Gagal refresh shop name: $e");
    }
  }

  // ==================== Guest AUTH (Offline Mode) ====================
  
  @override
  Future<Either<String, UserEntity>> signInAsGuest() async {
    try {
      await prefs.setBool(_guestSessionKey, true);
      final shopName = prefs.getString(_localShopNameKey) ?? 'BradPOS';
      return Right(
        UserEntity(
          id: 'offline_guest',
          email: 'guest@offline.local',
          name: 'Guest (Offline)',
          shopName: shopName,
          role: 'guest',
        ),
      );
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
      final response = await supabase.rpc('verify_karyawan_login', params: {
        'p_email': email,
        'p_password': password,
      });

      if (response == null || (response as List).isEmpty) {
        return const Left('Email atau password karyawan salah');
      }

      final karyawanData = response[0];
      
      // Tarik info toko Owner si karyawan
      String shopName = 'BradPOS';
      try {
        final ownerProfile = await supabase.from('profiles').select('shop_name').eq('id', karyawanData['owner_id']).single();
        shopName = ownerProfile['shop_name'] ?? 'BradPOS';
      } catch (_) {
        // Fallback jika profile owner tidak ditemukan/tidak ada kolom shop_name
      }
      
      await prefs.setString(_localShopNameKey, shopName);

      final user = UserEntity(
        id: karyawanData['id'],
        email: karyawanData['email'],
        name: karyawanData['full_name'],
        shopName: shopName,
        role: 'karyawan',
        ownerId: karyawanData['owner_id'],
      );

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
      if (e.toString().contains('duplicate')) return const Left('Email karyawan sudah terdaftar');
      return Left('Gagal membuat akun karyawan: ${e.toString()}');
    }
  }
}
