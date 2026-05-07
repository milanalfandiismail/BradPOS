import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/services/stock_alert_service.dart';
import 'package:bradpos/domain/entities/dashboard_stats.dart';
import 'package:bradpos/domain/repositories/dashboard_repository.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;
  final StockAlertService stockAlertService;
  final AuthRepository authRepository;

  DashboardBloc({
    required this.repository,
    required this.stockAlertService,
    required this.authRepository,
  }) : super(DashboardInitial()) {
    on<LoadDashboardStats>((event, emit) async {
      emit(DashboardLoading());

      final results = await Future.wait([
        repository.getDashboardStats(),
        _getLowStockCount(),
        _getOutOfStockCount(),
      ]);

      final statsResult = results[0] as Either<String, DashboardStats>;
      final lowStock = results[1] as int;
      final outOfStock = results[2] as int;

      stockAlertService.lastTotalAlert = lowStock + outOfStock;

      statsResult.fold(
        (failure) => emit(DashboardError(failure)),
        (stats) => emit(
          DashboardLoaded(stats,
            lowStockCount: lowStock,
            outOfStockCount: outOfStock,
          ),
        ),
      );
    });
  }

  Future<int> _getLowStockCount() async {
    final userResult = await authRepository.getCurrentUser();
    final user = userResult.getOrElse(() => null);
    if (user == null) return 0;
    final userId = (user.isKaryawan && user.ownerId != null)
        ? user.ownerId!
        : user.id;
    return stockAlertService.getLowStockCount(userId);
  }

  Future<int> _getOutOfStockCount() async {
    final userResult = await authRepository.getCurrentUser();
    final user = userResult.getOrElse(() => null);
    if (user == null) return 0;
    final userId = (user.isKaryawan && user.ownerId != null)
        ? user.ownerId!
        : user.id;
    return stockAlertService.getOutOfStockCount(userId);
  }
}
