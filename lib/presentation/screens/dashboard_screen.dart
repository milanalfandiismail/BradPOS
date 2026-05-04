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
import 'package:bradpos/presentation/screens/login_screen.dart';
import 'package:bradpos/presentation/screens/karyawan_list_screen.dart';
import 'package:bradpos/presentation/screens/inventory_screen.dart';
import 'package:bradpos/presentation/screens/cashier_screen.dart';
import 'package:bradpos/presentation/screens/history_screen.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';
import 'package:bradpos/core/widgets/brad_header.dart';
import 'package:bradpos/presentation/widgets/settings_modal.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white,
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String shopName = 'BradPOS';
                    if (state is AuthAuthenticated) {
                      shopName = state.user.shopName ?? 'BradPOS';
                    }
                    return BradHeader(
                      title: 'Beranda',
                      subtitle: shopName,
                      leadingIcon: Icons.home_rounded,
                      onSettingsTap: () => SettingsModal.show(context),
                    );
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<AuthBloc>().syncService.syncAll();
                    context.read<DashboardBloc>().add(LoadDashboardStats());
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                              return const Center(child: CircularProgressIndicator());
                            } else if (state is DashboardLoaded) {
                              return Column(
                                children: [
                                  LowStockBanner(
                                    lowStockCount: state.lowStockCount,
                                    outOfStockCount: state.outOfStockCount,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const InventoryScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildStats(state.stats),
                                ],
                              );
                            } else if (state is DashboardError) {
                              return Center(child: Text(state.message));
                            }
                            return const SizedBox();
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSalesPerformance(),
                        const SizedBox(height: 24),
                        _buildBottomActions(context),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (_, _) => MainBottomNavBar(
            activeLabel: 'DASHBOARD',
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'Cashier';
        if (state is AuthAuthenticated) {
          userName = state.user.name ?? state.user.email.split('@')[0];
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RINGKASAN TOKO',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Halo, $userName! 👋',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Berikut laporan performa toko Anda hari ini.",
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainActions(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final bool isOwner = state is AuthAuthenticated && state.user.isOwner;
        return Row(
          children: [
            QuickActionButton(
              title: 'Buka Kasir',
              icon: Icons.point_of_sale_rounded,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CashierScreen())),
            ),
            if (isOwner) ...[
              const SizedBox(width: 12),
              QuickActionButton(
                title: 'Karyawan',
                icon: Icons.people_alt_rounded,
                backgroundColor: const Color(0xFFE0F2FE),
                foregroundColor: const Color(0xFF0369A1),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const KaryawanListScreen()),
                ),
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

  Widget _buildStats(DashboardStats stats) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return Column(
      children: [
        StatCard(
          title: 'Penjualan Hari Ini',
          value: currencyFormat.format(stats.totalSales),
          growth: stats.salesGrowth,
          icon: Icons.payments_rounded,
          iconColor: const Color(0xFF059669),
          iconBgColor: const Color(0xFFD1FAE5),
        ),
        const SizedBox(height: 16),
        StatCard(
          title: 'Total Transaksi',
          value: stats.totalTransactions.toString(),
          growth: stats.transactionsGrowth,
          icon: Icons.receipt_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFDBEAFE),
        ),
      ],
    );
  }

  Widget _buildSalesPerformance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Penjualan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const Text(
            'Trend per jam hari ini',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (index) {
                final heights = [45.0, 85.0, 65.0, 100.0, 75.0, 95.0];
                final times = [
                  '08:00',
                  '10:00',
                  '12:00',
                  '14:00',
                  '16:00',
                  '18:00',
                ];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: index == 3
                            ? AppColors.primary
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      times[index],
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
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

  Widget _buildBottomActions(BuildContext context) {
    return Column(
      children: [
        QuickActionCard(
          title: 'Transaksi Baru',
          subtitle: 'Proses belanja pelanggan',
          icon: Icons.add_shopping_cart_rounded,
          iconBgColor: AppColors.primary,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CashierScreen())),
        ),
        const SizedBox(height: 12),
        QuickActionCard(
          title: 'Stok Barang',
          subtitle: 'Cek sisa stok & harga',
          icon: Icons.inventory_2_rounded,
          iconBgColor: AppColors.secondary,
          badgeCount: _getTotalStockAlert(context),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const InventoryScreen())),
        ),
        const SizedBox(height: 12),
        QuickActionCard(
          title: 'Riwayat Transaksi',
          subtitle: 'Daftar nota belanja',
          icon: Icons.receipt_long_rounded,
          iconBgColor: Colors.purple,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
        ),
      ],
    );
  }
}
