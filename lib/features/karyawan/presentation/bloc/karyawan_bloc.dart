import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/karyawan_usecases.dart';
import 'karyawan_event.dart';
import 'karyawan_state.dart';

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
    on<LoadKaryawanList>((event, emit) async {
      emit(KaryawanLoading());
      final result = await getKaryawans();
      result.fold(
        (failure) => emit(KaryawanError(failure)),
        (karyawanList) => emit(KaryawanListLoaded(karyawanList)),
      );
    });

    on<CreateKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await addKaryawan(event.karyawan);
      result.fold(
        (failure) => emit(KaryawanError(failure)),
        (karyawan) {
          emit(const KaryawanOperationSuccess("Karyawan berhasil ditambahkan"));
          add(LoadKaryawanList());
        },
      );
    });

    on<EditKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await updateKaryawan(event.karyawan);
      result.fold(
        (failure) => emit(KaryawanError(failure)),
        (karyawan) {
          emit(const KaryawanOperationSuccess("Karyawan berhasil diperbarui"));
          add(LoadKaryawanList());
        },
      );
    });

    on<RemoveKaryawan>((event, emit) async {
      emit(KaryawanLoading());
      final result = await deleteKaryawan(event.id);
      result.fold(
        (failure) => emit(KaryawanError(failure)),
        (_) {
          emit(const KaryawanOperationSuccess("Karyawan berhasil dihapus"));
          add(LoadKaryawanList());
        },
      );
    });
  }
}
