import 'package:dartz/dartz.dart';
import '../entities/karyawan.dart';
import '../repositories/karyawan_repository.dart';

/// Use Case: Mengambil daftar semua karyawan milik Owner yang sedang login.
class GetKaryawans {
  final KaryawanRepository repository;
  GetKaryawans(this.repository);

  Future<Either<String, List<Karyawan>>> call() async {
    return await repository.getKaryawans();
  }
}

/// Use Case: Menambahkan data karyawan baru ke database.
class AddKaryawan {
  final KaryawanRepository repository;
  AddKaryawan(this.repository);

  Future<Either<String, Karyawan>> call(Karyawan karyawan) async {
    return await repository.addKaryawan(karyawan);
  }
}

/// Use Case: Memperbarui informasi karyawan yang sudah ada.
class UpdateKaryawan {
  final KaryawanRepository repository;
  UpdateKaryawan(this.repository);

  Future<Either<String, Karyawan>> call(Karyawan karyawan) async {
    return await repository.updateKaryawan(karyawan);
  }
}

/// Use Case: Menghapus data karyawan dari database.
class DeleteKaryawan {
  final KaryawanRepository repository;
  DeleteKaryawan(this.repository);

  Future<Either<String, void>> call(String id) async {
    return await repository.deleteKaryawan(id);
  }
}
