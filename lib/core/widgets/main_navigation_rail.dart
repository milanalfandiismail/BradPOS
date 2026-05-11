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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/screens/login_screen.dart';

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

    return Container(
      width: isLandscape ? 52 : 72,
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: NavigationRail(
              selectedIndex: _getSelectedIndex(),
              onDestinationSelected: (index) => _onDestinationSelected(context, index),
              labelType: isLandscape ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              groupAlignment: -1.0,
              minWidth: isLandscape ? 52 : 72,
              selectedIconTheme: IconThemeData(
                color: AppColors.primary,
                size: isLandscape ? 18 : 24,
              ),
              unselectedIconTheme: IconThemeData(
                color: const Color(0xFF64748B),
                size: isLandscape ? 18 : 24,
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
              leading: null,
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                IconButton(
                  onPressed: () => SettingsModal.show(context),
                  icon: Icon(
                    Icons.settings_outlined,
                    color: activeLabel == 'SETTINGS' ? AppColors.primary : const Color(0xFF64748B),
                    size: isLandscape ? 18 : 24,
                  ),
                  tooltip: 'Settings',
                ),
                const SizedBox(height: 4),
                IconButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(SignOutRequested());
                    AppNavigator.pushReplacement(context, const LoginScreen());
                  },
                  icon: Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: isLandscape ? 18 : 24,
                  ),
                  tooltip: 'Logout',
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int? _getSelectedIndex() {
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
        return null;
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
