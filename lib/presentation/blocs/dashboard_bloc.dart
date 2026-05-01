import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

/// Bloc untuk mengelola state halaman Dashboard.
/// Menangani pemuatan statistik penjualan harian.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc({
    required this.repository,
  }) : super(DashboardInitial()) {
    on<LoadDashboardStats>((event, emit) async {
      emit(DashboardLoading());
      
      final result = await repository.getDashboardStats();
      result.fold(
        (failure) => emit(DashboardError(failure)),
        (stats) => emit(DashboardLoaded(stats)),
      );
    });
  }
}

