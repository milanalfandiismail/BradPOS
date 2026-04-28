import 'package:bradpos/features/main/presentation/pages/main_screen.dart';
import 'package:bradpos/features/settings/presentation/screens/settings_page.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey),
          ),
        ),
        title: const Text(
          "QuickCash POS",
          style: TextStyle(
            color: Color(0xFF1A1D1E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "DASHBOARD TOKO",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Halo, Kasir!",
              style: TextStyle(
                color: Color(0xFF1A1D1E),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Inilah yang terjadi di stasiun Anda hari ini.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Top Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Berpindah ke tab Cashier (Indeks 1)
                      MainScreen.of(context)?.setIndex(1);
                    },
                    icon: const Icon(Icons.storefront, size: 20),
                    label: const Text("Mulai Kasir"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Berpindah ke tab Inventory (Indeks 2)
                      MainScreen.of(context)?.setIndex(2);
                    },
                    icon: const Icon(Icons.inventory_2_outlined, size: 20),
                    label: const Text("Inventaris"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8EEF9),
                      foregroundColor: const Color(0xFF4A5568),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Cards
            const _StatCard(
              title: "Total Penjualan Hari Ini",
              value: "Rp 4.280.500",
              icon: Icons.payments_outlined,
              iconColor: Color(0xFF007A5E),
              badgeText: "+ 12%",
              badgeColor: Color(0xFFE6F4F1),
              badgeTextColor: Color(0xFF007A5E),
            ),
            const SizedBox(height: 16),
            const _StatCard(
              title: "Transaksi",
              value: "142",
              icon: Icons.receipt_long_outlined,
              iconColor: Color(0xFF3182CE),
              badgeText: "+ 8%",
              badgeColor: Color(0xFFEBF8FF),
              badgeTextColor: Color(0xFF3182CE),
            ),
            const SizedBox(height: 16),
            const _StatCard(
              title: "Rata-rata Penjualan",
              value: "Rp 300.000",
              icon: Icons.analytics_outlined,
              iconColor: Color(0xFF718096),
              badgeText: "~ Statis",
              badgeColor: Color(0xFFEDF2F7),
              badgeTextColor: Color(0xFF718096),
            ),
            const SizedBox(height: 24),

            // Sales Performance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Performa Penjualan",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1D1E),
                            ),
                          ),
                          Text(
                            "Tren per jam hari ini",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _ToggleButton(label: "Hari Ini", isSelected: true),
                            _ToggleButton(label: "Kemarin", isSelected: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Placeholder for Chart
                  SizedBox(
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text("08:00", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text("10:00", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text("12:00", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text("14:00", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text("16:00", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text("18:00", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _ActionTile(
              onTap: () {
                MainScreen.of(context)?.setIndex(1);
              },
              title: "Transaksi Baru",
              subtitle: "Proses pembelian pelanggan sekarang",
              icon: Icons.shopping_cart_outlined,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFF007A5E),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              onTap: () {
                MainScreen.of(context)?.setIndex(2);
              },
              title: "Cari Item",
              subtitle: "Cek stok dan detail harga",
              icon: Icons.search,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFF3182CE),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A1D1E),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _ToggleButton({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF1A1D1E) : Colors.grey,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1D1E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
