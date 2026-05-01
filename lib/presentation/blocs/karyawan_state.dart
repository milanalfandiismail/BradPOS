import 'package:equatable/equatable.dart';
import 'package:bradpos/domain/entities/karyawan.dart';

/// State yang dikeluarkan oleh KaryawanBloc untuk mengontrol tampilan UI.
abstract class KaryawanState extends Equatable {
  const KaryawanState();
  @override
  List<Object?> get props => [];
}

class KaryawanInitial extends KaryawanState {}

class KaryawanLoading extends KaryawanState {}

class KaryawanListLoaded extends KaryawanState {
  final List<Karyawan> karyawanList;
  const KaryawanListLoaded(this.karyawanList);
  @override
  List<Object?> get props => [karyawanList];
}

class KaryawanOperationSuccess extends KaryawanState {
  final String message;
  const KaryawanOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class KaryawanError extends KaryawanState {
  final String message;
  const KaryawanError(this.message);
  @override
  List<Object?> get props => [message];
}
