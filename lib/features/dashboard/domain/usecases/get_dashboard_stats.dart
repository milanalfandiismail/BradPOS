import 'package:dartz/dartz.dart';
import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

/// Use Case untuk mengambil statistik Dashboard.
/// Meneruskan permintaan ke DashboardRepository.
class GetDashboardStats {
  final DashboardRepository repository;

  GetDashboardStats(this.repository);

  Future<Either<String, DashboardStats>> call() async {
    return await repository.getDashboardStats();
  }
}
