import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/domain/repositories/karyawan_repository.dart';
import 'karyawan_event.dart';
import 'karyawan_state.dart';

/// Bloc untuk mengelola logika bisnis Manajemen Karyawan.
/// Menangani alur data dari UI ke Repository langsung (Layered Architecture).
class KaryawanBloc extends Bloc<KaryawanEvent, KaryawanState> {
  final KaryawanRepository repository;

  KaryawanBloc({required this.repository}) : super(KaryawanInitial()) {
    // Handler untuk memuat daftar seluruh karyawan
    on<LoadKaryawanList>((event, emit) async {
      emit(KaryawanLoading());
      final result = await repository.getKaryawans();
      result.fold(
        (failure) => emit(KaryawanError(failure)),
        (karyawanList) => emit(KaryawanListLoaded(karyawanList)),
      );
    });

    // Handler untuk menambah karyawan baru
    on<CreateKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await repository.addKaryawan(event.karyawan);
      result.fold((failure) => emit(KaryawanError(failure)), (karyawan) {
        emit(const KaryawanOperationSuccess("Karyawan berhasil ditambahkan"));
        add(LoadKaryawanList());
      });
    });

    // Handler untuk mengedit data karyawan
    on<EditKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await repository.updateKaryawan(event.karyawan);
      result.fold((failure) => emit(KaryawanError(failure)), (karyawan) {
        emit(const KaryawanOperationSuccess("Karyawan berhasil diperbarui"));
        add(LoadKaryawanList());
      });
    });

    // Handler untuk menghapus karyawan
    on<RemoveKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await repository.deleteKaryawan(event.id);
      result.fold((failure) => emit(KaryawanError(failure)), (_) {
        emit(const KaryawanOperationSuccess("Karyawan berhasil dihapus"));
        add(LoadKaryawanList());
      });
    });
  }
}
