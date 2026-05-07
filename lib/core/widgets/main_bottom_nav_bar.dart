import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/app_navigator.dart';
import 'package:bradpos/presentation/widgets/stock_alert_badge.dart';
import 'package:bradpos/presentation/screens/dashboard_screen.dart';
import 'package:bradpos/presentation/screens/cashier_screen.dart';
import 'package:bradpos/presentation/screens/inventory_screen.dart';
import 'package:bradpos/presentation/screens/history_screen.dart';
import 'package:bradpos/injection_container.dart' as di;
import 'package:bradpos/core/services/stock_alert_service.dart';

class MainBottomNavBar extends StatelessWidget {
  final String activeLabel;

  const MainBottomNavBar({
    super.key,
    required this.activeLabel,
  });

  int get _badgeCount => di.sl<StockAlertService>().lastTotalAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              Icons.grid_view_rounded,
              'DASHBOARD',
              activeLabel == 'DASHBOARD',
              () => _navigateTo(context, const DashboardScreen(), 'DASHBOARD'),
              badgeCount: 0,
            ),
            _buildNavItem(
              context,
              Icons.point_of_sale,
              'CASHIER',
              activeLabel == 'CASHIER',
              () => _navigateTo(context, const CashierScreen(), 'CASHIER'),
              badgeCount: 0,
            ),
            _buildNavItem(
              context,
              Icons.inventory_2_outlined,
              'INVENTORY',
              activeLabel == 'INVENTORY',
              () => _navigateTo(context, const InventoryScreen(), 'INVENTORY'),
              badgeCount: _badgeCount,
            ),
            _buildNavItem(
              context,
              Icons.history,
              'HISTORY',
              activeLabel == 'HISTORY',
              () => _navigateTo(context, const HistoryScreen(), 'HISTORY'),
              badgeCount: 0,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page, String label) {
    if (activeLabel != label) {
      AppNavigator.pushReplacement(context, page);
    }
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isActive)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 3),
          StockAlertBadge(
            count: badgeCount,
            color: AppColors.warning,
            child: Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
