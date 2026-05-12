import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';

class InventoryPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const InventoryPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 8 : 12,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageButton(
            onPressed: onPrevious,
            icon: Icons.chevron_left_rounded,
            isCompact: isLandscape,
          ),
          const SizedBox(width: 12),
          Text(
            '$currentPage / $totalPages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: isLandscape ? 12 : 14,
            ),
          ),
          const SizedBox(width: 12),
          _pageButton(
            onPressed: onNext,
            icon: Icons.chevron_right_rounded,
            isCompact: isLandscape,
          ),
        ],
      ),
    );
  }

  Widget _pageButton({
    VoidCallback? onPressed,
    required IconData icon,
    bool isCompact = false,
  }) {
    return Material(
      color: onPressed == null
          ? Colors.grey.shade50
          : AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
        child: Container(
          width: isCompact ? 32 : 40,
          height: isCompact ? 32 : 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: isCompact ? 18 : 22,
            color: onPressed == null ? Colors.grey.shade300 : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
