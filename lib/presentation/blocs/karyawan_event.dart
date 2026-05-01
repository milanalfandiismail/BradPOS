import 'package:equatable/equatable.dart';
import 'package:bradpos/domain/entities/karyawan.dart';

/// Event yang bisa dikirim ke KaryawanBloc untuk menjalankan operasi CRUD.
abstract class KaryawanEvent extends Equatable {
  const KaryawanEvent();
  @override
  List<Object?> get props => [];
}

class LoadKaryawanList extends KaryawanEvent {}

class CreateKaryawan extends KaryawanEvent {
  final Karyawan karyawan;
  const CreateKaryawan(this.karyawan);
  @override
  List<Object?> get props => [karyawan];
}

class EditKaryawan extends KaryawanEvent {
  final Karyawan karyawan;
  const EditKaryawan(this.karyawan);
  @override
  List<Object?> get props => [karyawan];
}

class RemoveKaryawan extends KaryawanEvent {
  final String id;
  const RemoveKaryawan(this.id);
  @override
  List<Object?> get props => [id];
}
