import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';

/// Widget kartu statistik di Dashboard (Total Sales, Transactions, Avg Ticket).
/// Menampilkan nilai, ikon, dan indikator pertumbuhan (naik/turun/stabil).
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final double? growth;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.growth,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (growth != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: growth! >= 0 ? AppColors.positiveLight : AppColors.neutralLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        growth! >= 0 ? Icons.trending_up : Icons.horizontal_rule,
                        size: 14,
                        color: growth! >= 0 ? AppColors.positive : AppColors.neutral,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        growth! == 0 ? 'Static' : '${growth!.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: growth! >= 0 ? AppColors.positive : AppColors.neutral,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
