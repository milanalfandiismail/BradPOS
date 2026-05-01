import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

/// Kontrak (Interface) untuk semua operasi Autentikasi di BradPOS.
/// Mendukung dua jenis login: Owner (Supabase Auth) dan Karyawan (Custom DB).
abstract class AuthRepository {
  // ==================== Owner Auth (Supabase Auth) ====================

  /// Login Owner menggunakan email dan password via Supabase.
  Future<Either<String, UserEntity>> signIn(String email, String password);

  /// Registrasi akun Owner baru via Supabase.
  Future<Either<String, UserEntity>> signUp(String email, String password, String fullName);

  /// Login Owner menggunakan akun Google (OAuth).
  Future<Either<String, UserEntity>> signInWithGoogle();

  /// Logout dari semua sesi (Owner maupun Karyawan).
  Future<Either<String, void>> signOut();

  /// Mengecek apakah ada sesi yang masih aktif saat aplikasi dibuka.
  Future<Either<String, UserEntity?>> getCurrentUser();

  /// Mengupdate nama toko (Hanya bisa dilakukan oleh Owner).
  Future<Either<String, void>> updateShopName(String shopName);

  /// Refresh nama toko dari server (Sinkronisasi profil).
  Future<void> refreshShopName();

  // ==================== Guest Auth (Offline Mode) ====================

  /// Login sebagai Guest (Offline Mode)
  Future<Either<String, UserEntity>> signInAsGuest();

  /// Mengecek apakah sesi saat ini adalah Guest
  bool isGuestMode();

  // ==================== Karyawan Auth (Custom Database) ====================

  /// Login Karyawan menggunakan email dan password yang tersimpan di tabel 'karyawan'.
  Future<Either<String, UserEntity>> signInAsKaryawan(String email, String password);

  /// Membuat akun karyawan baru (hanya bisa dilakukan oleh Owner).
  Future<Either<String, String>> createKaryawan(String fullName, String email, String password);
}
