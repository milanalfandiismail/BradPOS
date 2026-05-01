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
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/screens/login_screen.dart';
import 'package:bradpos/presentation/screens/karyawan_list_screen.dart';
import 'package:bradpos/presentation/screens/inventory_screen.dart';
import 'package:bradpos/presentation/screens/cashier_screen.dart';
import 'package:bradpos/core/widgets/main_bottom_nav_bar.dart';

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildGreeting(),
                const SizedBox(height: 24),
                _buildMainActions(context),
                const SizedBox(height: 24),
                BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    if (state is DashboardLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is DashboardLoaded) {
                      return _buildStats(state.stats);
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
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ),
        bottomNavigationBar: const MainBottomNavBar(activeLabel: 'DASHBOARD'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String shopName = 'BradPOS';
        bool isOwner = false;
        if (state is AuthAuthenticated) {
          shopName = state.user.shopName ?? 'BradPOS';
          isOwner = state.user.isOwner;
        }
        return Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BradPOS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
                  ),
                  InkWell(
                    onTap: isOwner ? () => _showEditShopNameDialog(context, shopName) : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            shopName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 20),
            ),
          ],
        );
      },
    );
  }

  void _showEditShopNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nama Toko', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Masukkan nama toko...',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<AuthBloc>().add(UpdateShopNameEvent(controller.text.trim()));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(onPressed: () { Navigator.pop(context); context.read<AuthBloc>().add(SignOutRequested()); }, child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'Cashier';
        if (state is AuthAuthenticated) userName = state.user.name ?? state.user.email.split('@')[0];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RINGKASAN TOKO', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            Text('Halo, $userName! 👋', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Text("Berikut laporan performa toko Anda hari ini.", style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
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
            QuickActionButton(title: 'Buka Kasir', icon: Icons.point_of_sale_rounded, backgroundColor: AppColors.primary, foregroundColor: Colors.white, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CashierScreen()))),
            if (isOwner) ...[
              const SizedBox(width: 12),
              QuickActionButton(title: 'Karyawan', icon: Icons.people_alt_rounded, backgroundColor: const Color(0xFFE0F2FE), foregroundColor: const Color(0xFF0369A1), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KaryawanListScreen()))),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStats(DashboardStats stats) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return Column(
      children: [
        StatCard(title: 'Penjualan Hari Ini', value: currencyFormat.format(stats.totalSales), growth: stats.salesGrowth, icon: Icons.payments_rounded, iconColor: const Color(0xFF059669), iconBgColor: const Color(0xFFD1FAE5)),
        const SizedBox(height: 16),
        StatCard(title: 'Total Transaksi', value: stats.totalTransactions.toString(), growth: stats.transactionsGrowth, icon: Icons.receipt_rounded, iconColor: const Color(0xFF2563EB), iconBgColor: const Color(0xFFDBEAFE)),
      ],
    );
  }

  Widget _buildSalesPerformance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grafik Penjualan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const Text('Trend per jam hari ini', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 30),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (index) {
                final heights = [45.0, 85.0, 65.0, 100.0, 75.0, 95.0];
                final times = ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00'];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: index == 3 ? AppColors.primary : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      times[index],
                      style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
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
        QuickActionCard(title: 'Transaksi Baru', subtitle: 'Proses belanja pelanggan', icon: Icons.add_shopping_cart_rounded, iconBgColor: AppColors.primary, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CashierScreen()))),
        const SizedBox(height: 12),
        QuickActionCard(title: 'Stok Barang', subtitle: 'Cek sisa stok & harga', icon: Icons.inventory_2_rounded, iconBgColor: AppColors.secondary, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InventoryScreen()))),
      ],
    );
  }
}
