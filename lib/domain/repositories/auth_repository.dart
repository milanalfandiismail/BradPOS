import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

/// Kontrak (Interface) untuk semua operasi Autentikasi di BradPOS.
/// Mendukung dua jenis login: Owner (Supabase Auth) dan Karyawan (Custom DB).
abstract class AuthRepository {
  // ==================== Owner Auth (Supabase Auth) ====================

  /// Login Owner menggunakan email dan password via Supabase.
  Future<Either<String, UserEntity>> signIn(String email, String password);

  /// Registrasi akun Owner baru via Supabase.
  Future<Either<String, UserEntity>> signUp(
    String email,
    String password,
    String fullName,
  );

  /// Login Owner menggunakan akun Google (OAuth).
  Future<Either<String, UserEntity>> signInWithGoogle();

  /// Logout dari semua sesi (Owner maupun Karyawan).
  Future<Either<String, void>> signOut();

  /// Mengecek apakah ada sesi yang masih aktif saat aplikasi dibuka.
  Future<Either<String, UserEntity?>> getCurrentUser();

  /// Mengupdate profil toko (Nama, Gambar).
  Future<Either<String, UserEntity>> updateProfile({
    String? fullName,
    String? shopName,
    String? shopId,
    String? remoteImage,
    String? localImage,
    String? address,
    String? phone,
  });

  /// Sinkronisasi profil lengkap dari server (Nama Toko, Alamat, HP, Gambar).
  Future<void> syncProfile();

  // ==================== Guest Auth (Offline Mode) ====================

  /// Login sebagai Guest (Offline Mode)
  Future<Either<String, UserEntity>> signInAsGuest();

  /// Mengecek apakah sesi saat ini adalah Guest
  bool isGuestMode();

  // ==================== Karyawan Auth (Custom Database) ====================

  /// Login Karyawan menggunakan email dan password yang tersimpan di tabel 'karyawan'.
  Future<Either<String, UserEntity>> signInAsKaryawan(
    String shopId,
    String name,
    String password,
  );

  /// Membuat akun karyawan baru (hanya bisa dilakukan oleh Owner).
  Future<Either<String, String>> createKaryawan(
    String fullName,
    String password,
  );
}
