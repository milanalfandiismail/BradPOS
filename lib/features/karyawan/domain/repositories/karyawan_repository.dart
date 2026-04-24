import 'package:dartz/dartz.dart';
import '../entities/karyawan.dart';

abstract class KaryawanRepository {
  Future<Either<String, List<Karyawan>>> getKaryawans();
  Future<Either<String, Karyawan>> addKaryawan(Karyawan karyawan);
  Future<Either<String, Karyawan>> updateKaryawan(Karyawan karyawan);
  Future<Either<String, void>> deleteKaryawan(String id);
}
