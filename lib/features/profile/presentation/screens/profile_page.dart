import 'package:bradpos/features/settings/presentation/screens/settings_page.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/images/mio.jpg'), // Menggunakan asset yang ada
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF007A5E), width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/images/mio.jpg'),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF007A5E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Sarah Miller",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
                  ),
                  const Text(
                    "ID Karyawan: EP-402-8821",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge("Kasir Senior", const Color(0xFFE6F4F1), const Color(0xFF007A5E)),
                      const SizedBox(width: 8),
                      _buildBadge("Terminal #402", const Color(0xFFE8F0FE), const Color(0xFF1967D2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBadge("Shift Aktif", const Color(0xFFF1F4FA), Colors.grey, isOutlined: true),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Today's Performance
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Performa Hari Ini",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
              ),
            ),
            const SizedBox(height: 16),
            _buildPerformanceCard(
              icon: Icons.payments_outlined,
              title: "Total Penjualan",
              value: "Rp 2.482.500",
              badge: "+ 12%",
              badgeColor: const Color(0xFFE6F4F1),
              badgeTextColor: const Color(0xFF007A5E),
            ),
            const SizedBox(height: 12),
            _buildPerformanceCard(
              icon: Icons.access_time,
              title: "Durasi Shift",
              value: "06:24 hr",
            ),
            const SizedBox(height: 12),
            _buildPerformanceCard(
              icon: Icons.receipt_long_outlined,
              title: "Transaksi",
              value: "142",
            ),
            const SizedBox(height: 32),

            // Account Management
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Manajemen Akun",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  _buildAccountTile(
                    icon: Icons.security_outlined,
                    iconColor: Colors.blue,
                    title: "Keamanan Akun",
                    subtitle: "Kelola 2FA dan perangkat login",
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildAccountTile(
                    icon: Icons.refresh,
                    iconColor: Colors.blue,
                    title: "Ganti Kata Sandi",
                    subtitle: "Perbarui kredensial keamanan Anda",
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildAccountTile(
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    title: "Keluar",
                    subtitle: "Akhiri sesi Anda saat ini",
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Footer
            const Text(
              "App Version 2.4.1 (Stable Build)",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Text(
              "© 2024 Ergo Technologies",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor, {bool isOutlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.white : bgColor,
        borderRadius: BorderRadius.circular(20),
        border: isOutlined ? Border.all(color: Colors.grey.withValues(alpha: 0.2)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPerformanceCard({
    required IconData icon,
    required String title,
    required String value,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF007A5E), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E))),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: TextStyle(color: badgeTextColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isDestructive ? Colors.red : const Color(0xFF1A1D1E),
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: () {},
    );
  }
}
