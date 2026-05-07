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
      // Ambil transaksi 7 hari terakhir
      final now = DateTime.now();
      final startOfPeriod = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final result = await transactionRepository.getTransactionsByRange(
        startOfPeriod,
        endOfPeriod,
      );

      return result.fold((failure) => Left(failure), (transactions) {
        // Filter transaksi khusus hari ini untuk ringkasan kartu
        final today = DateTime(now.year, now.month, now.day);
        final todayTransactions = transactions.where((t) =>
            t.createdAt.year == today.year &&
            t.createdAt.month == today.month &&
            t.createdAt.day == today.day).toList();

        final double totalSales = todayTransactions.fold(
          0.0,
          (sum, t) => sum + t.total,
        );
        final int totalTransactions = todayTransactions.length;
        final double avgTicket = totalTransactions > 0
            ? totalSales / totalTransactions
            : 0.0;

        // Hitung trend 7 hari terakhir
        final List<double> dailySales = List.filled(7, 0.0);
        for (final t in transactions) {
          final tDate = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
          final diff = today.difference(tDate).inDays;
          if (diff >= 0 && diff < 7) {
            dailySales[6 - diff] += t.total;
          }
        }

        final stats = DashboardStatsModel(
          totalSales: totalSales,
          salesGrowth: 0.0,
          totalTransactions: totalTransactions,
          transactionsGrowth: 0.0,
          avgTicketSize: avgTicket,
          ticketSizeGrowth: 0.0,
          dailySales: dailySales,
        );

        return Right(stats);
      });
    } catch (e) {
      return Left(e.toString());
    }
  }
}
