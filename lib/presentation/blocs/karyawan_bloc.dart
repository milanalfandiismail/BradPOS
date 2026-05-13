import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/domain/repositories/karyawan_repository.dart';
import 'package:bradpos/presentation/blocs/karyawan_event.dart';
import 'package:bradpos/presentation/blocs/karyawan_state.dart';

/// Bloc untuk mengelola logika bisnis Manajemen Karyawan.
/// Menangani alur data dari UI ke Repository langsung (Layered Architecture).
class KaryawanBloc extends Bloc<KaryawanEvent, KaryawanState> {
  final KaryawanRepository repository;
  int _currentFilterStatus = 0; // 0: Semua, 1: Aktif, 2: Nonaktif

  KaryawanBloc({required this.repository}) : super(KaryawanInitial()) {
    // Handler untuk memuat daftar seluruh karyawan
    on<LoadKaryawanList>((event, emit) async {
      emit(KaryawanLoading());
      _currentFilterStatus = event.filterStatus;

      // Konversi status ke bool? untuk repository
      bool? isActive;
      if (_currentFilterStatus == 1) isActive = true;
      if (_currentFilterStatus == 2) isActive = false;

      final result = await repository.getKaryawans(isActive: isActive);
      result.fold((failure) => emit(KaryawanError(failure)), (karyawanList) {
        // Debug
        // String statusLabel = 'Semua Status';
        // if (_currentFilterStatus == 1) statusLabel = 'Aktif';
        // if (_currentFilterStatus == 2) statusLabel = 'Nonaktif';

        // print("DEBUG: Memuat ${karyawanList.length} karyawan. Filter: $statusLabel");
        emit(KaryawanListLoaded(karyawanList, timestamp: DateTime.now()));
      });
    });

    // Handler untuk menambah karyawan baru
    on<CreateKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await repository.addKaryawan(event.karyawan);
      result.fold((failure) => emit(KaryawanError(failure)), (karyawan) {
        emit(const KaryawanOperationSuccess("Karyawan berhasil ditambahkan"));
        add(
          LoadKaryawanList(
            filterStatus: _currentFilterStatus,
            timestamp: DateTime.now(),
          ),
        );
      });
    });

    // Handler untuk mengedit data karyawan
    on<EditKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await repository.updateKaryawan(event.karyawan);
      result.fold((failure) => emit(KaryawanError(failure)), (karyawan) {
        emit(const KaryawanOperationSuccess("Karyawan berhasil diperbarui"));
        add(
          LoadKaryawanList(
            filterStatus: _currentFilterStatus,
            timestamp: DateTime.now(),
          ),
        );
      });
    });

    // Handler untuk menghapus karyawan
    on<RemoveKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await repository.deleteKaryawan(event.id);
      result.fold((failure) => emit(KaryawanError(failure)), (_) {
        emit(const KaryawanOperationSuccess("Karyawan berhasil dihapus"));
        add(
          LoadKaryawanList(
            filterStatus: _currentFilterStatus,
            timestamp: DateTime.now(),
          ),
        );
      });
    });
  }
}
