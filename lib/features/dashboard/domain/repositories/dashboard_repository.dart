import 'package:dartz/dartz.dart';
import '../entities/dashboard_stats.dart';

/// Kontrak (Interface) untuk pengambilan data statistik Dashboard.
abstract class DashboardRepository {
  /// Mengambil data statistik penjualan hari ini (total, transaksi, rata-rata).
  Future<Either<String, DashboardStats>> getDashboardStats();
}
