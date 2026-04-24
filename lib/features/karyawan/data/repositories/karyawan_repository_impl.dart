import 'package:dartz/dartz.dart';
import '../../domain/entities/karyawan.dart';
import '../../domain/repositories/karyawan_repository.dart';
import '../models/karyawan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KaryawanRepositoryImpl implements KaryawanRepository {
  final SupabaseClient supabase;
  final SharedPreferences prefs;

  KaryawanRepositoryImpl(this.supabase, this.prefs);

  static const String _karyawanSessionKey = 'karyawan_session';

  bool _isKaryawanSession() {
    return prefs.containsKey(_karyawanSessionKey);
  }

  @override
  Future<Either<String, List<Karyawan>>> getKaryawans() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      
      // If Karyawan is logged in, they can only see themselves or maybe nothing
      // For now, let's allow them to see the list but with owner_id from their session
      String? ownerId = userId;
      
      if (_isKaryawanSession()) {
        // Implementation for Karyawan viewing list could go here
        // For now, let's assume they can't manage others
        return const Right([]); 
      }

      if (ownerId == null) return const Left("User not authenticated");

      final response = await supabase
          .from("karyawan")
          .select("*")
          .eq("owner_id", ownerId)
          .order('created_at', ascending: false);

      final karyawanList = response
          .map((row) => KaryawanModel.fromMap(row))
          .toList();
      return Right(karyawanList);
    } catch (e) {
      return Left("Load failed: $e");
    }
  }

  @override
  Future<Either<String, Karyawan>> addKaryawan(Karyawan karyawan) async {
    if (_isKaryawanSession()) {
      return const Left("Maaf, Karyawan tidak memiliki akses untuk menambah data karyawan baru.");
    }

    try {
      final response = await supabase.rpc(
        "create_karyawan",
        params: {
          "p_full_name": karyawan.name,
          "p_email": karyawan.email,
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
    if (_isKaryawanSession()) {
      return const Left("Maaf, Karyawan tidak memiliki akses untuk mengubah data karyawan.");
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return const Left("User not authenticated");

      await supabase
          .from("karyawan")
          .update({
            "full_name": karyawan.name,
            "email": karyawan.email,
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
    if (_isKaryawanSession()) {
      return const Left("Maaf, Karyawan tidak memiliki akses untuk menghapus data karyawan.");
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return const Left("User not authenticated");

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
