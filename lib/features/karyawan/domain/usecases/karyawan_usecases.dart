import 'package:dartz/dartz.dart';
import '../entities/karyawan.dart';
import '../repositories/karyawan_repository.dart';

class GetKaryawans {
  final KaryawanRepository repository;
  GetKaryawans(this.repository);

  Future<Either<String, List<Karyawan>>> call() async {
    return await repository.getKaryawans();
  }
}

class AddKaryawan {
  final KaryawanRepository repository;
  AddKaryawan(this.repository);

  Future<Either<String, Karyawan>> call(Karyawan karyawan) async {
    return await repository.addKaryawan(karyawan);
  }
}

class UpdateKaryawan {
  final KaryawanRepository repository;
  UpdateKaryawan(this.repository);

  Future<Either<String, Karyawan>> call(Karyawan karyawan) async {
    return await repository.updateKaryawan(karyawan);
  }
}

class DeleteKaryawan {
  final KaryawanRepository repository;
  DeleteKaryawan(this.repository);

  Future<Either<String, void>> call(String id) async {
    return await repository.deleteKaryawan(id);
  }
}
