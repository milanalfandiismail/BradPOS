import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/karyawan_usecases.dart';
import 'karyawan_event.dart';
import 'karyawan_state.dart';

/// Bloc untuk mengelola logika bisnis Manajemen Karyawan.
/// Menangani alur data dari UI ke Usecase dan mengembalikan State yang sesuai.
class KaryawanBloc extends Bloc<KaryawanEvent, KaryawanState> {
  final GetKaryawans getKaryawans;
  final AddKaryawan addKaryawan;
  final UpdateKaryawan updateKaryawan;
  final DeleteKaryawan deleteKaryawan;

  KaryawanBloc({
    required this.getKaryawans,
    required this.addKaryawan,
    required this.updateKaryawan,
    required this.deleteKaryawan,
  }) : super(KaryawanInitial()) {
    
    // Handler untuk memuat daftar seluruh karyawan
    on<LoadKaryawanList>((event, emit) async {
      emit(KaryawanLoading());
      final result = await getKaryawans();
      result.fold(
        (failure) => emit(KaryawanError(failure)),
        (karyawanList) => emit(KaryawanListLoaded(karyawanList)),
      );
    });

    // Handler untuk menambah karyawan baru
    on<CreateKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await addKaryawan(event.karyawan);
      result.fold(
        (failure) => emit(KaryawanError(failure)),
        (karyawan) {
          emit(const KaryawanOperationSuccess("Karyawan berhasil ditambahkan"));
          // Setelah berhasil, trigger loading ulang daftar karyawan
          add(LoadKaryawanList());
        },
      );
    });

    // Handler untuk mengedit data karyawan
    on<EditKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await updateKaryawan(event.karyawan);
      result.fold(
        (failure) => emit(KaryawanError(failure)),
        (karyawan) {
          emit(const KaryawanOperationSuccess("Karyawan berhasil diperbarui"));
          // Refresh daftar setelah update
          add(LoadKaryawanList());
        },
      );
    });

    // Handler untuk menghapus karyawan
    on<RemoveKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await deleteKaryawan(event.id);
      result.fold(
        (failure) => emit(KaryawanError(failure)),
        (_) {
          emit(const KaryawanOperationSuccess("Karyawan berhasil dihapus"));
          // Refresh daftar setelah delete
          add(LoadKaryawanList());
        },
      );
    });
  }
}
