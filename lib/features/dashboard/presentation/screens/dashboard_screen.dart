import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_state.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/quick_action_card.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../karyawan/presentation/screens/karyawan_list_screen.dart';

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
                _buildBottomActions(),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.person, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'QuickCash POS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            // Show logout confirmation
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<AuthBloc>().add(SignOutRequested());
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout, color: AppColors.textSecondary),
        ),
      ],
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
              'STORE DASHBOARD',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hello, $userName!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Here's what's happening at your station today.",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
              title: 'Start Cashier',
              icon: Icons.point_of_sale,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              onTap: () {},
            ),
            if (isOwner) ...[
              const SizedBox(width: 12),
              QuickActionButton(
                title: 'Karyawan',
                icon: Icons.people_outline,
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: const Color(0xFF1E40AF),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const KaryawanListScreen()),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStats(DashboardStats stats) {
    final currencyFormat = NumberFormat.simpleCurrency();
    return Column(
      children: [
        StatCard(
          title: 'Total Sales Today',
          value: currencyFormat.format(stats.totalSales),
          growth: stats.salesGrowth,
          icon: Icons.payments_outlined,
          iconColor: const Color(0xFF065F46),
          iconBgColor: const Color(0xFFD1FAE5),
        ),
        const SizedBox(height: 16),
        StatCard(
          title: 'Transactions',
          value: stats.totalTransactions.toString(),
          growth: stats.transactionsGrowth,
          icon: Icons.receipt_long_outlined,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFDBEAFE),
        ),
        const SizedBox(height: 16),
        StatCard(
          title: 'Avg. Ticket Size',
          value: currencyFormat.format(stats.avgTicketSize),
          growth: stats.ticketSizeGrowth == 0 ? null : stats.ticketSizeGrowth,
          icon: Icons.bar_chart_outlined,
          iconColor: const Color(0xFF475569),
          iconBgColor: const Color(0xFFF1F5F9),
        ),
      ],
    );
  }

  Widget _buildSalesPerformance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Performance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Hourly trend for today',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildToggleButton('Today', true),
                    _buildToggleButton('Yesterday', false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Simple Chart Placeholder
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 40,
                      height: [40, 80, 60, 100, 70, 90][index].toDouble(),
                      decoration: BoxDecoration(
                        color: index == 3
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${08 + index * 2}:00',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
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

  Widget _buildToggleButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: isActive
            ? [
                const BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        QuickActionCard(
          title: 'New Transaction',
          subtitle: 'Process a customer purchase now',
          icon: Icons.add_shopping_cart,
          iconBgColor: AppColors.primary,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        QuickActionCard(
          title: 'Look Up Items',
          subtitle: 'Check stock and pricing details',
          icon: Icons.search,
          iconBgColor: AppColors.secondary,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.grid_view_rounded, 'DASHBOARD', true),
              _buildNavItem(Icons.point_of_sale, 'CASHIER', false),
              _buildNavItem(Icons.inventory_2_outlined, 'INVENTORY', false),
              _buildNavItem(Icons.history, 'HISTORY', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
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
    );
  }
}
