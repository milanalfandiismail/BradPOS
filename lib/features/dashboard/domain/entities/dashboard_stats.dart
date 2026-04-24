import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final double totalSales;
  final double salesGrowth;
  final int totalTransactions;
  final double transactionsGrowth;
  final double avgTicketSize;
  final double ticketSizeGrowth;

  const DashboardStats({
    required this.totalSales,
    required this.salesGrowth,
    required this.totalTransactions,
    required this.transactionsGrowth,
    required this.avgTicketSize,
    required this.ticketSizeGrowth,
  });

  @override
  List<Object?> get props => [
        totalSales,
        salesGrowth,
        totalTransactions,
        transactionsGrowth,
        avgTicketSize,
        ticketSizeGrowth,
      ];
}
