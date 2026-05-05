import 'package:dartz/dartz.dart';
import 'package:bradpos/domain/entities/karyawan.dart';
import 'package:bradpos/domain/repositories/karyawan_repository.dart';
import 'package:bradpos/data/models/karyawan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementasi Manajemen Data Karyawan.
/// Melayani operasi CRUD (Create, Read, Update, Delete) untuk data karyawan.
class KaryawanRepositoryImpl implements KaryawanRepository {
  final SupabaseClient supabase;
  final SharedPreferences prefs;

  KaryawanRepositoryImpl(this.supabase, this.prefs);

  static const String _karyawanSessionKey = 'karyawan_session';

  /// Mengecek apakah pengguna saat ini masuk sebagai Karyawan (bukan Owner).
  bool _isKaryawanSession() {
    return prefs.containsKey(_karyawanSessionKey);
  }

  @override
  Future<Either<String, List<Karyawan>>> getKaryawans() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      // Jika yang login adalah Karyawan, mereka tidak boleh melihat daftar karyawan lain.
      if (_isKaryawanSession()) {
        return const Right([]);
      }

      if (userId == null) return const Left("Anda harus login sebagai Owner.");

      // Ambil data dari tabel 'karyawan' yang dimiliki oleh Owner ini
      final response = await supabase
          .from("karyawan")
          .select("*")
          .eq("owner_id", userId)
          .order('created_at', ascending: false);

      final karyawanList = response
          .map((row) => KaryawanModel.fromMap(row))
          .toList();
      return Right(karyawanList);
    } catch (e) {
      return Left("Gagal memuat data: $e");
    }
  }

  @override
  Future<Either<String, Karyawan>> addKaryawan(Karyawan karyawan) async {
    // Larang Karyawan menambah karyawan lain (RBAC)
    if (_isKaryawanSession()) {
      return const Left(
        "Maaf, Karyawan tidak memiliki akses untuk menambah data karyawan baru.",
      );
    }

    try {
      // Gunakan RPC agar pembuatan akun karyawan tersentralisasi di server
      final response = await supabase.rpc(
        "create_karyawan_v2",
        params: {
          "p_full_name": karyawan.name,
          "p_password": karyawan.password,
        },
      );

      final newKaryawan = karyawan.copyWith(
        id: response.toString(),
        ownerId: supabase.auth.currentUser?.id ?? '',
        createdAt: DateTime.now(),
      );

      return Right(newKaryawan);
    } catch (e) {
      // Fallback jika RPC gagal, coba insert langsung (pastikan kebijakan RLS mengizinkan)
      try {
        final userId = supabase.auth.currentUser?.id;
        final response = await supabase
            .from("karyawan")
            .insert(karyawan.toMap()..['owner_id'] = userId)
            .select()
            .single();

        return Right(KaryawanModel.fromMap(response));
      } catch (innerError) {
        return Left("Gagal menambah karyawan: $e");
      }
    }
  }

  @override
  Future<Either<String, Karyawan>> updateKaryawan(Karyawan karyawan) async {
    // Larang Karyawan mengedit data karyawan lain (RBAC)
    if (_isKaryawanSession()) {
      return const Left(
        "Maaf, Karyawan tidak memiliki akses untuk mengubah data karyawan.",
      );
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return const Left("User tidak terautentikasi.");

      await supabase
          .from("karyawan")
          .update({
            "full_name": karyawan.name,
            "is_active": karyawan.isActive,
          })
          .eq("id", karyawan.id)
          .eq("owner_id", userId);

      return Right(karyawan);
    } catch (e) {
      return Left("Gagal memperbarui karyawan: $e");
    }
  }

  @override
  Future<Either<String, void>> deleteKaryawan(String id) async {
    // Larang Karyawan menghapus data (RBAC)
    if (_isKaryawanSession()) {
      return const Left(
        "Maaf, Karyawan tidak memiliki akses untuk menghapus data karyawan.",
      );
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return const Left("User tidak terautentikasi.");

      await supabase
          .from("karyawan")
          .delete()
          .eq("id", id)
          .eq("owner_id", userId);

      return const Right(null);
    } catch (e) {
      return Left("Gagal menghapus karyawan: $e");
    }
  }
}
