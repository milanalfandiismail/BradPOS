import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';

class LowStockBanner extends StatelessWidget {
  final int lowStockCount;
  final int outOfStockCount;
  final VoidCallback onTap;

  const LowStockBanner({
    super.key,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = lowStockCount + outOfStockCount;
    if (total <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: outOfStockCount > 0
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: outOfStockCount > 0
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                outOfStockCount > 0 ? Icons.error_outline : Icons.warning_amber_rounded,
                color: outOfStockCount > 0 ? AppColors.error : AppColors.warning,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _buildMessage(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: outOfStockCount > 0 ? AppColors.error : AppColors.warning,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _buildMessage() {
    if (outOfStockCount > 0 && lowStockCount > 0) {
      return '$outOfStockCount produk habis, $lowStockCount stok menipis. Cek sekarang!';
    } else if (outOfStockCount > 0) {
      return '$outOfStockCount produk sudah habis stok. Segera restok!';
    } else {
      return '$lowStockCount produk stok menipis. Cek sekarang!';
    }
  }
}
