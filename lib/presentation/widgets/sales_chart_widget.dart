import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';

class SalesChartWidget extends StatelessWidget {
  final List<double> dailySales;
  final bool isCompact;

  const SalesChartWidget({
    super.key,
    required this.dailySales,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Penjualan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (!isCompact)
            const Text(
              'Trend per hari',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          SizedBox(height: isCompact ? 12 : 30),
          SizedBox(
            height: isCompact ? 120 : 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final sales = index < dailySales.length ? dailySales[index] : 0.0;
                final maxSales = dailySales.fold(0.0, (m, v) => v > m ? v : m);
                final barMaxHeight = isCompact ? 80.0 : 100.0;
                final barHeight = maxSales > 0 ? (sales / maxSales) * barMaxHeight : 0.0;

                final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                final now = DateTime.now();
                final date = now.subtract(Duration(days: 6 - index));
                final dayLabel = days[date.weekday - 1];

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatCompact(sales),
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 8,
                        fontWeight: FontWeight.bold,
                        color: index == 6 ? AppColors.primary : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: isCompact ? 18 : 28,
                      height: barHeight < 4 ? 4 : barHeight,
                      decoration: BoxDecoration(
                        color: index == 6 ? AppColors.primary : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(isCompact ? 3 : 6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 9,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value <= 0) return '';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}rb';
    return value.toStringAsFixed(0);
  }
}
