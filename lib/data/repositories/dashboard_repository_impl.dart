import 'package:dartz/dartz.dart';
import 'package:bradpos/domain/entities/dashboard_stats.dart';
import 'package:bradpos/domain/repositories/dashboard_repository.dart';
import 'package:bradpos/data/models/dashboard_stats_model.dart';

/// Implementasi Repository Dashboard.
/// Saat ini menggunakan data dummy. Nanti akan terhubung ke Supabase.
class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<Either<String, DashboardStats>> getDashboardStats() async {
    try {
      // Simulating network/database delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      const stats = DashboardStatsModel(
        totalSales: 4280.50,
        salesGrowth: 12.0,
        totalTransactions: 142,
        transactionsGrowth: 8.0,
        avgTicketSize: 30.14,
        ticketSizeGrowth: 0.0,
      );
      
      return Right(stats);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
