import 'package:equatable/equatable.dart';

/// Entitas Statistik Dashboard.
/// Menyimpan ringkasan data penjualan yang ditampilkan di halaman utama.
class DashboardStats extends Equatable {
  /// Total penjualan hari ini (dalam mata uang).
  final double totalSales;

  /// Persentase pertumbuhan penjualan dibanding kemarin.
  final double salesGrowth;

  /// Jumlah total transaksi hari ini.
  final int totalTransactions;

  /// Persentase pertumbuhan jumlah transaksi.
  final double transactionsGrowth;

  /// Rata-rata nilai per transaksi.
  final double avgTicketSize;

  /// Persentase pertumbuhan rata-rata transaksi.
  final double ticketSizeGrowth;

  /// Data penjualan harian untuk grafik (7 hari terakhir).
  final List<double> dailySales;

  const DashboardStats({
    required this.totalSales,
    required this.salesGrowth,
    required this.totalTransactions,
    required this.transactionsGrowth,
    required this.avgTicketSize,
    required this.ticketSizeGrowth,
    this.dailySales = const [],
  });

  DashboardStats copyWith({
    double? totalSales,
    double? salesGrowth,
    int? totalTransactions,
    double? transactionsGrowth,
    double? avgTicketSize,
    double? ticketSizeGrowth,
    List<double>? dailySales,
  }) {
    return DashboardStats(
      totalSales: totalSales ?? this.totalSales,
      salesGrowth: salesGrowth ?? this.salesGrowth,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      transactionsGrowth: transactionsGrowth ?? this.transactionsGrowth,
      avgTicketSize: avgTicketSize ?? this.avgTicketSize,
      ticketSizeGrowth: ticketSizeGrowth ?? this.ticketSizeGrowth,
      dailySales: dailySales ?? this.dailySales,
    );
  }

  @override
  List<Object?> get props => [
    totalSales,
    salesGrowth,
    totalTransactions,
    transactionsGrowth,
    avgTicketSize,
    ticketSizeGrowth,
    dailySales,
  ];
}
