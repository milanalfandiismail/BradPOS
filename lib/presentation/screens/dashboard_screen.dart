import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/dashboard_bloc.dart';
import 'package:bradpos/presentation/blocs/dashboard_state.dart';
import 'package:bradpos/domain/entities/dashboard_stats.dart';
import 'package:bradpos/presentation/widgets/stat_card.dart';
import 'package:bradpos/presentation/widgets/quick_action_button.dart';
import 'package:bradpos/presentation/widgets/quick_action_card.dart';
import 'package:bradpos/presentation/widgets/low_stock_banner.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/screens/karyawan_list_screen.dart';
import 'package:bradpos/presentation/screens/inventory_screen.dart';
import 'package:bradpos/presentation/screens/cashier_screen.dart';
import 'package:bradpos/presentation/screens/history_screen.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/settings_modal.dart';
import 'package:bradpos/core/utils/app_navigator.dart';

import 'package:bradpos/core/widgets/main_navigation_rail.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data immediately on screen entry
    context.read<DashboardBloc>().add(LoadDashboardStats());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            if (isLandscape) const MainNavigationRail(activeLabel: 'DASHBOARD'),
            if (isLandscape)
              const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: Column(
                children: [
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      String shopName = 'BradPOS';
                      if (state is AuthAuthenticated) {
                        shopName = state.user.shopName ?? 'BradPOS';
                      }
                      return BradHeader(
                        title: 'Beranda',
                        subtitle: shopName,
                        leadingIcon: Icons.home_rounded,
                        showBottomBorder: true,
                        onSettingsTap: () => SettingsModal.show(context),
                        actions: isLandscape
                            ? [
                                IconButton(
                                  onPressed: () {
                                    context
                                        .read<AuthBloc>()
                                        .syncService
                                        .syncAll();
                                    context
                                        .read<DashboardBloc>()
                                        .add(LoadDashboardStats());
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Menyingkronkan data...'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.sync_rounded,
                                    color: Color(0xFF64748B),
                                    size: 18,
                                  ),
                                  tooltip: 'Sync',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ]
                            : null,
                      );
                    },
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<AuthBloc>().syncService.syncAll();
                        context.read<DashboardBloc>().add(LoadDashboardStats());
                        await Future.delayed(const Duration(seconds: 1));
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (isLandscape) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildGreeting(isCompact: true),
                                    const SizedBox(height: 10),
                                    _buildMainActions(context, isCompact: true),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              BlocBuilder<
                                                DashboardBloc,
                                                DashboardState
                                              >(
                                                builder: (context, state) {
                                                  if (state
                                                      is DashboardLoading) {
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  } else if (state
                                                      is DashboardLoaded) {
                                                    return Column(
                                                      children: [
                                                        LowStockBanner(
                                                          lowStockCount: state
                                                              .lowStockCount,
                                                          outOfStockCount: state
                                                              .outOfStockCount,
                                                          onTap: () =>
                                                              AppNavigator.push(
                                                                context,
                                                                const InventoryScreen(),
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        _buildStats(
                                                          state.stats,
                                                          isLandscape: true,
                                                          isCompact: true,
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                  return const SizedBox();
                                                },
                                              ),
                                              const SizedBox(height: 12),
                                              _buildBottomActions(
                                                context,
                                                isCompact: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 4,
                                          child:
                                              BlocBuilder<
                                                DashboardBloc,
                                                DashboardState
                                              >(
                                                builder: (context, state) {
                                                  if (state
                                                      is DashboardLoaded) {
                                                    return _buildSalesPerformance(
                                                      state.stats.dailySales,
                                                      isCompact: true,
                                                    );
                                                  }
                                                  return const SizedBox();
                                                },
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Portrait Mode
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                _buildGreeting(),
                                const SizedBox(height: 24),
                                _buildMainActions(context),
                                const SizedBox(height: 24),
                                BlocBuilder<DashboardBloc, DashboardState>(
                                  builder: (context, state) {
                                    if (state is DashboardLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (state is DashboardLoaded) {
                                      return Column(
                                        children: [
                                          LowStockBanner(
                                            lowStockCount: state.lowStockCount,
                                            outOfStockCount:
                                                state.outOfStockCount,
                                            onTap: () => AppNavigator.push(
                                              context,
                                              const InventoryScreen(),
                                            ),
                                          ),
                                          _buildStats(state.stats),
                                          const SizedBox(height: 24),
                                          _buildSalesPerformance(
                                            state.stats.dailySales,
                                          ),
                                        ],
                                      );
                                    } else if (state is DashboardError) {
                                      return Center(child: Text(state.message));
                                    }
                                    return const SizedBox();
                                  },
                                ),
                                const SizedBox(height: 24),
                                _buildBottomActions(context),
                                const SizedBox(height: 100),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isLandscape
          ? null
          : BlocBuilder<DashboardBloc, DashboardState>(
              builder: (_, _) =>
                  const MainBottomNavBar(activeLabel: 'DASHBOARD'),
            ),
    );
  }

  Widget _buildGreeting({bool isCompact = false}) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'Cashier';
        if (state is AuthAuthenticated) {
          userName = state.user.name ?? state.user.email.split('@')[0];
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RINGKASAN TOKO',
              style: TextStyle(
                fontSize: isCompact ? 9 : 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: isCompact ? 4 : 8),
            Text(
              'Halo, $userName! 👋',
              style: TextStyle(
                fontSize: isCompact ? 18 : 26,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: isCompact ? 2 : 4),
            Text(
              "Berikut laporan performa toko Anda hari ini.",
              style: TextStyle(
                fontSize: isCompact ? 11 : 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainActions(BuildContext context, {bool isCompact = false}) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final bool isOwner = state is AuthAuthenticated && state.user.isOwner;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuickActionButton(
              isCompact: isCompact,
              title: 'Kasir',
              icon: Icons.point_of_sale_rounded,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onTap: () => AppNavigator.push(context, const CashierScreen()),
            ),
            if (isOwner) ...[
              const SizedBox(width: 8),
              QuickActionButton(
                isCompact: isCompact,
                title: 'Karyawan',
                icon: Icons.people_alt_rounded,
                backgroundColor: const Color(0xFFE0F2FE),
                foregroundColor: const Color(0xFF0369A1),
                onTap: () =>
                    AppNavigator.push(context, const KaryawanListScreen()),
              ),
            ],
          ],
        );
      },
    );
  }

  int _getTotalStockAlert(BuildContext context) {
    final state = context.read<DashboardBloc>().state;
    if (state is DashboardLoaded) {
      return state.lowStockCount + state.outOfStockCount;
    }
    return 0;
  }

  Widget _buildStats(
    DashboardStats stats, {
    bool isLandscape = false,
    bool isCompact = false,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final cards = [
      StatCard(
        isCompact: isCompact,
        title: 'Penjualan',
        value: currencyFormat.format(stats.totalSales),
        icon: Icons.payments_rounded,
        iconColor: const Color(0xFF059669),
        iconBgColor: const Color(0xFFD1FAE5),
      ),
      StatCard(
        isCompact: isCompact,
        title: 'Transaksi',
        value: stats.totalTransactions.toString(),
        icon: Icons.receipt_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBgColor: const Color(0xFFDBEAFE),
      ),
    ];

    if (isLandscape) {
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 10),
          Expanded(child: cards[1]),
        ],
      );
    }

    return Column(children: cards);
  }

  Widget _buildSalesPerformance(
    List<double> dailySales, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.2,
        ), // Consistent border for chart
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Consistent shadow
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
              fontSize: isCompact ? 14 : 16,
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
            height: isCompact ? 100 : 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final sales = index < dailySales.length
                    ? dailySales[index]
                    : 0.0;

                double maxSales = dailySales.fold(0.0, (m, v) => v > m ? v : m);
                if (maxSales == 0) maxSales = 1.0;

                final barMaxHeight = isCompact ? 65.0 : 100.0;
                final barHeight = (sales / maxSales) * barMaxHeight;

                final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                final now = DateTime.now();
                final date = now.subtract(Duration(days: 6 - index));
                final dayLabel = days[date.weekday - 1];

                String formatCompact(double value) {
                  if (value <= 0) return '';
                  if (value >= 1000000) {
                    return '${(value / 1000000).toStringAsFixed(1)}jt';
                  }
                  if (value >= 1000) {
                    return '${(value / 1000).toStringAsFixed(0)}rb';
                  }
                  return value.toStringAsFixed(0);
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatCompact(sales),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: index == 6
                            ? AppColors.primary
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: isCompact ? 18 : 28,
                      height: barHeight < 4 ? 4 : barHeight,
                      decoration: BoxDecoration(
                        color: index == 6
                            ? AppColors.primary
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(isCompact ? 3 : 6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: isCompact ? 8 : 9,
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

  Widget _buildBottomActions(BuildContext context, {bool isCompact = false}) {
    final actions = [
      QuickActionCard(
        isCompact: isCompact,
        title: 'Transaksi',
        subtitle: 'Kasir',
        icon: Icons.add_shopping_cart_rounded,
        iconBgColor: AppColors.primary,
        onTap: () => AppNavigator.push(context, const CashierScreen()),
      ),
      QuickActionCard(
        isCompact: isCompact,
        title: 'Stok',
        subtitle: 'Inventory',
        icon: Icons.inventory_2_rounded,
        iconBgColor: AppColors.secondary,
        badgeCount: _getTotalStockAlert(context),
        onTap: () => AppNavigator.push(context, const InventoryScreen()),
      ),
      QuickActionCard(
        isCompact: isCompact,
        title: 'Riwayat',
        subtitle: 'History',
        icon: Icons.receipt_long_rounded,
        iconBgColor: Colors.purple,
        onTap: () => AppNavigator.push(context, const HistoryScreen()),
      ),
    ];

    if (isCompact) {
      return Row(
        children: [
          Expanded(child: actions[0]),
          const SizedBox(width: 8),
          Expanded(child: actions[1]),
          const SizedBox(width: 8),
          Expanded(child: actions[2]),
        ],
      );
    }

    return Column(
      children: [
        actions[0],
        const SizedBox(height: 12),
        actions[1],
        const SizedBox(height: 12),
        actions[2],
      ],
    );
  }
}
