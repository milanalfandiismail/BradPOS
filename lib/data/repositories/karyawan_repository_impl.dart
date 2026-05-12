import 'package:dartz/dartz.dart';
import 'package:bradpos/domain/entities/karyawan.dart';
import 'package:bradpos/domain/repositories/karyawan_repository.dart';
import 'package:bradpos/data/models/karyawan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bradpos/core/sync/sync_utils.dart';
import 'package:bradpos/data/data_sources/karyawan_local_data_source.dart';
import 'package:bradpos/data/data_sources/karyawan_remote_data_source.dart';

class KaryawanRepositoryImpl implements KaryawanRepository {
  final SupabaseClient supabase;
  final KaryawanLocalDataSource localDataSource;
  final KaryawanRemoteDataSource remoteDataSource;

  KaryawanRepositoryImpl({
    required this.supabase,
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<String, List<Karyawan>>> getKaryawans() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return const Left("Anda harus login.");

      // Offline-first: Ambil dari local SQLite
      final localData = await localDataSource.getKaryawans(userId);
      final list = localData.map((e) => KaryawanModel.fromMap(e)).toList();
      
      // Jika lokal kosong, coba tarik dari remote sekali (Initial PULL)
      if (list.isEmpty) {
        try {
          final remoteData = await remoteDataSource.getKaryawans(userId);
          await localDataSource.saveKaryawans(remoteData);
          final updatedList = remoteData.map((e) => KaryawanModel.fromMap(e)).toList();
          return Right(updatedList);
        } catch (e) {
          return Right(list); // Tetap kembalikan list kosong jika remote gagal
        }
      }

      return Right(list);
    } catch (e) {
      return Left("Gagal memuat data: $e");
    }
  }

  @override
  Future<Either<String, Karyawan>> addKaryawan(Karyawan karyawan) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return const Left("Akses ditolak.");

      final hashedPassword = SyncUtils.hashPassword(karyawan.password);
      
      // 1. Simpan ke Remote (Supabase)
      final remoteResult = await remoteDataSource.createKaryawan({
        'owner_id': userId,
        'full_name': karyawan.name,
        'password_hash': hashedPassword,
        'is_active': karyawan.isActive,
      });

      Karyawan resultKaryawan = KaryawanModel.fromMap(remoteResult);

      // 2. Jika ada gambar lokal, upload
      if (karyawan.localImage != null && karyawan.localImage!.isNotEmpty) {
        final remoteImageUrl = await remoteDataSource.uploadImage(
          karyawan.localImage!,
          resultKaryawan.id,
        );
        if (remoteImageUrl != null) {
          // Update remote_image URL di DB
          await remoteDataSource.updateKaryawan(resultKaryawan.id, {
            'remote_image': remoteImageUrl,
            'local_image': karyawan.localImage,
          });
          resultKaryawan = resultKaryawan.copyWith(
            remoteImage: remoteImageUrl,
            localImage: karyawan.localImage,
          );
        }
      }

      // 3. Simpan ke Local SQLite (Cache)
      await localDataSource.saveKaryawan(KaryawanModel.fromEntity(resultKaryawan).toMap());

      return Right(resultKaryawan);
    } catch (e) {
      return Left("Gagal menambah karyawan: $e");
    }
  }

  @override
  Future<Either<String, Karyawan>> updateKaryawan(Karyawan karyawan) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return const Left("User tidak terautentikasi.");

      String? remoteImageUrl = karyawan.remoteImage;

      // 1. Jika gambar lokal baru dipilih
      if (karyawan.localImage != null && 
          karyawan.localImage!.isNotEmpty && 
          !karyawan.localImage!.startsWith('http')) {
        
        // Hapus image lama di storage jika ada
        if (karyawan.remoteImage != null) {
          await remoteDataSource.deleteImage(karyawan.remoteImage!);
        }

        // Upload baru
        remoteImageUrl = await remoteDataSource.uploadImage(
          karyawan.localImage!,
          karyawan.id,
        );
      }

      final Map<String, dynamic> updateData = {
        "full_name": karyawan.name,
        "is_active": karyawan.isActive,
        "remote_image": remoteImageUrl,
        "local_image": karyawan.localImage,
      };

      if (karyawan.password.isNotEmpty) {
        updateData["password_hash"] = SyncUtils.hashPassword(karyawan.password);
      }

      // 2. Update Remote
      await remoteDataSource.updateKaryawan(karyawan.id, updateData);

      // 3. Update Local
      final updatedKaryawan = karyawan.copyWith(remoteImage: remoteImageUrl);
      final localMap = KaryawanModel.fromEntity(updatedKaryawan).toMap();
      
      if (karyawan.password.isNotEmpty) {
        localMap['password_hash'] = SyncUtils.hashPassword(karyawan.password);
      } else {
        final allLocal = await localDataSource.getKaryawans(userId);
        final existing = allLocal.firstWhere((e) => e['id'] == karyawan.id);
        localMap['password_hash'] = existing['password_hash'];
      }
      
      await localDataSource.saveKaryawan(localMap);

      return Right(updatedKaryawan);
    } catch (e) {
      return Left("Gagal memperbarui karyawan: $e");
    }
  }

  @override
  Future<Either<String, void>> deleteKaryawan(String id) async {
    try {
      // 1. Ambil data untuk hapus image di storage
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final allLocal = await localDataSource.getKaryawans(userId);
        final existing = allLocal.firstWhere((e) => e['id'] == id);
        final imageUrl = existing['remote_image'] as String?;
        if (imageUrl != null) {
          await remoteDataSource.deleteImage(imageUrl);
        }
      }

      // 2. Delete Remote & Local
      await remoteDataSource.deleteKaryawan(id);
      await localDataSource.deleteKaryawan(id);

      return const Right(null);
    } catch (e) {
      return Left("Gagal menghapus karyawan: $e");
    }
  }

}
