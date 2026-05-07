import 'package:equatable/equatable.dart';
import 'package:bradpos/domain/entities/dashboard_stats.dart';

/// Event yang bisa dikirim ke DashboardBloc.
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardStats extends DashboardEvent {}

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final int lowStockCount;
  final int outOfStockCount;

  const DashboardLoaded(
    this.stats, {
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
  });

  @override
  List<Object?> get props => [stats, lowStockCount, outOfStockCount];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
