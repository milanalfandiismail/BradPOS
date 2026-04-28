import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  const PaymentPage({super.key, required this.totalAmount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = 'Cash';
  String amountReceived = "0.00";

  void _onKeyPress(String value) {
    setState(() {
      if (amountReceived == "0.00") {
        amountReceived = value;
      } else {
        amountReceived += value;
      }
    });
  }

  void _clearAmount() {
    setState(() {
      amountReceived = "0.00";
    });
  }

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
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Payment Methods
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 16),
                  _buildPaymentMethodItem("Tunai", Icons.payments_outlined),
                  const SizedBox(height: 12),
                  _buildPaymentMethodItem("QRIS", Icons.qr_code_scanner),
                  const SizedBox(height: 12),
                  _buildPaymentMethodItem("Kartu", Icons.credit_card),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount Received & Keypad
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Jumlah Diterima", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text("Rp $amountReceived", style: const TextStyle(color: Color(0xFF007A5E), fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _clearAmount,
                        icon: const Icon(Icons.backspace_outlined, size: 16, color: Color(0xFF007A5E)),
                        label: const Text("Hapus", style: TextStyle(color: Color(0xFF007A5E))),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildKeypad(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Connection Status
            _buildStatusTile(Icons.qr_code_2, "QRIS Dinamis", "Siap dipindai"),
            const SizedBox(height: 12),
            _buildStatusTile(Icons.contactless, "Terminal Kartu", "ID Terminal: 4421"),
            const SizedBox(height: 16),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Ringkasan Pesanan", style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(8)),
                        child: const Text("8 Item", style: TextStyle(color: Color(0xFF1967D2), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildSummaryItem("Espresso Roast (Besar)", "Jml: 2", 12.50),
                  _buildSummaryItem("Artisan Croissant", "Jml: 1", 4.75),
                  _buildSummaryItem("Avocado Sourdough", "Jml: 1", 14.20),
                  const Divider(height: 32),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF1FDF5), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildTotalRow("Total Tagihan", widget.totalAmount, isPrimary: true),
                        const SizedBox(height: 8),
                        _buildTotalRow("Sisa Tagihan", widget.totalAmount, isDanger: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Konfirmasi Pembayaran"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005D47),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batalkan Pesanan", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(String title, IconData icon) {
    bool isSelected = selectedMethod == title;
    return InkWell(
      onTap: () => setState(() => selectedMethod = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F2EF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF007A5E) : Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF007A5E) : Colors.grey),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF007A5E) : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final List<String> keys = ["1", "2", "3", "5rb", "4", "5", "6", "10rb", "7", "8", "9", "20rb", "0", "00", ".", "50rb"];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        String key = keys[index];
        bool isPreset = key.endsWith('rb');
        return InkWell(
          onTap: () {
            if (isPreset) {
              String val = "";
              if (key == "5rb") val = "5000";
              else if (key == "10rb") val = "10000";
              else if (key == "20rb") val = "20000";
              else if (key == "50rb") val = "50000";
              setState(() => amountReceived = val);
            } else {
              _onKeyPress(key);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isPreset ? const Color(0xFFE8F0FE) : const Color(0xFFF1F4FA),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPreset ? const Color(0xFF1967D2) : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F4FA), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF007A5E)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String name, String qty, double price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(qty, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text("Rp ${price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isPrimary = false, bool isDanger = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isPrimary ? FontWeight.normal : FontWeight.bold, fontSize: 13, color: isDanger ? Colors.red : Colors.black)),
        Text(
          "Rp ${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isPrimary ? 14 : 13,
            color: isPrimary ? const Color(0xFF007A5E) : (isDanger ? Colors.red : Colors.black),
          ),
        ),
      ],
    );
  }
}
