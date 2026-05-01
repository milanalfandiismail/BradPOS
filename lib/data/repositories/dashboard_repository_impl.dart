import 'package:dartz/dartz.dart';
import 'package:bradpos/domain/entities/dashboard_stats.dart';
import 'package:bradpos/domain/repositories/dashboard_repository.dart';
import 'package:bradpos/domain/repositories/transaction_repository.dart';
import 'package:bradpos/data/models/dashboard_stats_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final TransactionRepository transactionRepository;

  DashboardRepositoryImpl({required this.transactionRepository});

  @override
  Future<Either<String, DashboardStats>> getDashboardStats() async {
    try {
      // Ambil transaksi hari ini
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final result = await transactionRepository.getTransactionsByRange(startOfDay, endOfDay);
      
      return result.fold(
        (failure) => Left(failure),
        (transactions) {
          final double totalSales = transactions.fold(0.0, (sum, t) => sum + t.total);
          final int totalTransactions = transactions.length;
          final double avgTicket = totalTransactions > 0 ? totalSales / totalTransactions : 0.0;

          final stats = DashboardStatsModel(
            totalSales: totalSales,
            salesGrowth: 0.0, // Bisa dihitung jika ambil data kemarin
            totalTransactions: totalTransactions,
            transactionsGrowth: 0.0,
            avgTicketSize: avgTicket,
            ticketSizeGrowth: 0.0,
          );
          
          return Right(stats);
        },
      );
    } catch (e) {
      return Left(e.toString());
    }
  }
}
