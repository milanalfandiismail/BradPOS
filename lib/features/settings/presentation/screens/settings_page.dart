import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool salesTaxEnabled = true;
  bool taxInclusivePricing = false;
  String selectedLanguage = 'Bahasa Indonesia';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1D1E)),
          onPressed: () => Navigator.pop(context),
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
            icon: const Icon(Icons.settings, color: Color(0xFF007A5E)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "KONFIGURASI TERMINAL",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pengaturan",
              style: TextStyle(
                color: Color(0xFF1A1D1E),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Konfigurasi preferensi terminal dan toko Anda",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Store Information
            _buildSettingsSection(
              title: "INFORMASI TOKO",
              icon: Icons.store_outlined,
              children: [
                _buildListTile(
                  title: "Nama Toko",
                  subtitle: "ErgoPOS Store #402 - Pusat Kota",
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildListTile(
                  title: "Alamat",
                  subtitle: "Jl. Evergreen No. 742, Springfield, OR",
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Printer Setup
            _buildSettingsSection(
              title: "PENGATURAN PRINTER",
              icon: Icons.print_outlined,
              children: [
                _buildPrinterTile(
                  icon: Icons.bluetooth,
                  title: "Bluetooth Printer",
                  status: "Terhubung: Star MCP31",
                  statusColor: const Color(0xFF007A5E),
                  buttonText: "Konfigurasi",
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildPrinterTile(
                  icon: Icons.settings_input_component,
                  title: "IP Printer",
                  status: "192.168.1.155 (Terputus)",
                  statusColor: Colors.grey,
                  buttonText: "Hubungkan",
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tax Configuration
            _buildSettingsSection(
              title: "KONFIGURASI PAJAK",
              icon: Icons.receipt_long_outlined,
              children: [
                SwitchListTile(
                  value: salesTaxEnabled,
                  onChanged: (val) => setState(() => salesTaxEnabled = val),
                  title: const Text("Pajak Penjualan (Standar)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("8.5% diterapkan ke semua item kena pajak", style: TextStyle(fontSize: 12)),
                  activeColor: const Color(0xFF007A5E),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  value: taxInclusivePricing,
                  onChanged: (val) => setState(() => taxInclusivePricing = val),
                  title: const Text("Harga Termasuk Pajak", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Tampilkan harga dengan pajak yang sudah termasuk", style: TextStyle(fontSize: 12)),
                  activeColor: const Color(0xFF007A5E),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Language Preferences
            _buildSettingsSection(
              title: "PREFERENSI BAHASA",
              icon: Icons.language,
              children: [
                _buildLanguageOption("Bahasa Indonesia", isSelected: selectedLanguage == "Bahasa Indonesia"),
                _buildLanguageOption("English (US)", isSelected: selectedLanguage == "English (US)"),
                _buildLanguageOption("Español", isSelected: selectedLanguage == "Español"),
                _buildLanguageOption("Français", isSelected: selectedLanguage == "Français"),
              ],
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Keluar dari Terminal", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F4FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF007A5E)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A5E),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile({required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF1A1D1E), fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildPrinterTile({
    required IconData icon,
    required String title,
    required String status,
    required Color statusColor,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF007A5E), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(buttonText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language, {required bool isSelected}) {
    return InkWell(
      onTap: () => setState(() => selectedLanguage = language),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? const Color(0xFF007A5E) : Colors.grey.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFF1FDF5) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF007A5E) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              language,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF007A5E) : const Color(0xFF1A1D1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
