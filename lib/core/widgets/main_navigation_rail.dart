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
import 'package:bradpos/presentation/widgets/settings_modal.dart';

class MainNavigationRail extends StatelessWidget {
  final String activeLabel;

  const MainNavigationRail({
    super.key,
    required this.activeLabel,
  });

  int get _badgeCount => di.sl<StockAlertService>().lastTotalAlert;

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Aggressive hiding to prevent vertical overflow on small landscape screens
        final bool showLeading = constraints.maxHeight > 400;
        final bool showTrailing = constraints.maxHeight > 350;

        return NavigationRail(
          selectedIndex: _getSelectedIndex(),
          onDestinationSelected: (index) => _onDestinationSelected(context, index),
          labelType: isLandscape ? NavigationRailLabelType.none : NavigationRailLabelType.all,
          backgroundColor: Colors.white,
          minWidth: isLandscape ? 52 : 72,
          selectedIconTheme: IconThemeData(
            color: AppColors.primary,
            size: isLandscape ? 20 : 24,
          ),
          unselectedIconTheme: IconThemeData(
            color: const Color(0xFF64748B),
            size: isLandscape ? 20 : 24,
          ),
          selectedLabelTextStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelTextStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
          ),
          leading: !showLeading ? null : Padding(
            padding: EdgeInsets.symmetric(vertical: isLandscape ? 4 : 8),
            child: Container(
              width: isLandscape ? 32 : 36,
              height: isLandscape ? 32 : 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.point_of_sale_rounded, color: AppColors.primary, size: isLandscape ? 14 : 18),
              ),
            ),
          ),
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: Text('DASHBOARD'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.point_of_sale),
              label: Text('CASHIER'),
            ),
            NavigationRailDestination(
              icon: StockAlertBadge(
                count: _badgeCount,
                color: AppColors.warning,
                child: const Icon(Icons.inventory_2_outlined),
              ),
              label: const Text('INVENTORY'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.history),
              label: Text('HISTORY'),
            ),
          ],
          trailing: !showTrailing ? null : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => SettingsModal.show(context),
                icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B), size: 18),
                tooltip: 'Settings',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () => SettingsModal.show(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                tooltip: 'Logout',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  int _getSelectedIndex() {
    switch (activeLabel) {
      case 'DASHBOARD':
        return 0;
      case 'CASHIER':
        return 1;
      case 'INVENTORY':
        return 2;
      case 'HISTORY':
        return 3;
      default:
        return 0;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    Widget page;
    String label;
    switch (index) {
      case 0:
        page = const DashboardScreen();
        label = 'DASHBOARD';
        break;
      case 1:
        page = const CashierScreen();
        label = 'CASHIER';
        break;
      case 2:
        page = const InventoryScreen();
        label = 'INVENTORY';
        break;
      case 3:
        page = const HistoryScreen();
        label = 'HISTORY';
        break;
      default:
        return;
    }

    if (activeLabel != label) {
      AppNavigator.pushReplacement(context, page);
    }
  }
}
