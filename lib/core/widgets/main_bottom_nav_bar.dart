import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'package:bradpos/presentation/screens/dashboard_screen.dart';
import 'package:bradpos/presentation/screens/cashier_screen.dart';
import 'package:bradpos/presentation/screens/inventory_screen.dart';
import 'package:bradpos/presentation/screens/history_screen.dart';

class MainBottomNavBar extends StatelessWidget {
  final String activeLabel;

  const MainBottomNavBar({
    super.key, 
    required this.activeLabel,
  });

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
            ),
            _buildNavItem(
              context,
              Icons.point_of_sale,
              'CASHIER',
              activeLabel == 'CASHIER',
              () => _navigateTo(context, const CashierScreen(), 'CASHIER'),
            ),
            _buildNavItem(
              context,
              Icons.inventory_2_outlined,
              'INVENTORY',
              activeLabel == 'INVENTORY',
              () => _navigateTo(context, const InventoryScreen(), 'INVENTORY'),
            ),
            _buildNavItem(
              context,
              Icons.history,
              'HISTORY',
              activeLabel == 'HISTORY',
              () => _navigateTo(context, const HistoryScreen(), 'HISTORY'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page, String label) {
    if (activeLabel != label) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
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
