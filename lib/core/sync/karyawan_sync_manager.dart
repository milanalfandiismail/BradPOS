import 'package:bradpos/data/models/karyawan_model.dart';
import 'package:flutter/foundation.dart';
import 'package:bradpos/data/data_sources/karyawan_local_data_source.dart';
import 'package:bradpos/data/data_sources/karyawan_remote_data_source.dart';

class KaryawanSyncManager {
  final KaryawanLocalDataSource localDataSource;
  final KaryawanRemoteDataSource remoteDataSource;

  KaryawanSyncManager({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<void> pull(String ownerId) async {
    try {
      debugPrint("KaryawanSync: Pulling staff from server...");
      final remoteItems = await remoteDataSource.getKaryawans(ownerId);
      
      if (remoteItems.isEmpty) {
        debugPrint("KaryawanSync: Tidak ada data karyawan di server.");
        return;
      }

      debugPrint("KaryawanSync: Berhasil menarik ${remoteItems.length} karyawan");
      
      // Filter data melalui model agar kolom yang tidak sesuai (seperti email lama) dibuang
      final cleanItems = remoteItems.map((e) => KaryawanModel.fromMap(e).toMap()).toList();

      await localDataSource.saveKaryawans(cleanItems);
    } catch (e) {
      debugPrint("KaryawanSync Pull Failed: $e");
    }
  }
}
