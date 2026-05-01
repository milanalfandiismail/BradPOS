import 'package:dartz/dartz.dart';
import '../entities/karyawan.dart';

/// Kontrak (Interface) untuk manajemen data karyawan.
/// Menentukan operasi apa saja yang tersedia untuk mengelola entitas Karyawan.
abstract class KaryawanRepository {
  /// Mengambil daftar semua karyawan yang berada di bawah Owner yang sedang login.
  Future<Either<String, List<Karyawan>>> getKaryawans();

  /// Menambahkan data karyawan baru ke database.
  Future<Either<String, Karyawan>> addKaryawan(Karyawan karyawan);

  /// Memperbarui informasi data karyawan yang sudah ada.
  Future<Either<String, Karyawan>> updateKaryawan(Karyawan karyawan);

  /// Menghapus data karyawan secara permanen dari database.
  Future<Either<String, void>> deleteKaryawan(String id);
}
