import 'package:bradpos/domain/entities/dashboard_stats.dart';

/// Model data untuk statistik Dashboard.
/// Bertugas mengubah data JSON dari API/database menjadi objek DashboardStats.
class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalSales,
    required super.salesGrowth,
    required super.totalTransactions,
    required super.transactionsGrowth,
    required super.avgTicketSize,
    required super.ticketSizeGrowth,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalSales: (json['totalSales'] as num).toDouble(),
      salesGrowth: (json['salesGrowth'] as num).toDouble(),
      totalTransactions: json['totalTransactions'] as int,
      transactionsGrowth: (json['transactionsGrowth'] as num).toDouble(),
      avgTicketSize: (json['avgTicketSize'] as num).toDouble(),
      ticketSizeGrowth: (json['ticketSizeGrowth'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSales': totalSales,
      'salesGrowth': salesGrowth,
      'totalTransactions': totalTransactions,
      'transactionsGrowth': transactionsGrowth,
      'avgTicketSize': avgTicketSize,
      'ticketSizeGrowth': ticketSizeGrowth,
    };
  }
}
