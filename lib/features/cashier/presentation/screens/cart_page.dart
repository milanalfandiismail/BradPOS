import 'package:bradpos/features/cashier/presentation/screens/payment_page.dart';
import 'package:bradpos/features/settings/presentation/screens/settings_page.dart';
import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final String subtitle;
  final double price;
  final int quantity;
  final String imagePath;

  CartItem({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.quantity,
    required this.imagePath,
  });
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final List<CartItem> cartItems = [
    CartItem(
      name: "Artisan Flat White",
      subtitle: "Oat Milk, Extra Hot",
      price: 4.50,
      quantity: 2,
      imagePath: "assets/images/mio.jpg",
    ),
    CartItem(
      name: "Butter Croissant",
      subtitle: "Warm, Extra Butter",
      price: 3.50,
      quantity: 1,
      imagePath: "assets/images/mio.jpg",
    ),
    CartItem(
      name: "Avocado Smash",
      subtitle: "Poached Egg, Sourdough",
      price: 12.00,
      quantity: 1,
      imagePath: "assets/images/mio.jpg",
    ),
  ];

  String paymentMethod = 'Card';

  @override
  Widget build(BuildContext context) {
    double subtotal = cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
    double tax = subtotal * 0.10;
    double total = subtotal + tax;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
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
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
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
        child: Column(
          children: [
            // Current Receipt Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Pesanan Saat Ini",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
                  ),
                  Text(
                    "${cartItems.length} TOTAL ITEM",
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            // Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(item.imagePath, width: 70, height: 70, fit: BoxFit.cover, 
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], width: 70, height: 70, child: const Icon(Icons.image_outlined, color: Colors.grey))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(item.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text("Rp ${item.price.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFF007A5E), fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: () {}),
                              Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(icon: const Icon(Icons.add, size: 16, color: Color(0xFF007A5E)), onPressed: () {}),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ringkasan Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(width: 40, height: 3, color: const Color(0xFF007A5E)),
                  const SizedBox(height: 20),
                  _buildSummaryRow("Subtotal (${cartItems.length} item)", "Rp ${subtotal.toStringAsFixed(0)}"),
                  const SizedBox(height: 12),
                  _buildSummaryRow("Pajak (PPN 10%)", "Rp ${tax.toStringAsFixed(0)}"),
                  const SizedBox(height: 16),
                  const Text("KODE PROMO / DISKON", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Expanded(child: TextField(decoration: InputDecoration(hintText: "Masukkan kode", border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey)))),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007A5E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text("GUNAKAN"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Total Tagihan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Text("Termasuk pajak", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      Text("Rp ${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF005D47))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildPaymentButton(Icons.payments_outlined, "Tunai", paymentMethod == 'Cash', () => setState(() => paymentMethod = 'Cash'))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPaymentButton(Icons.credit_card, "Kartu", paymentMethod == 'Card', () => setState(() => paymentMethod = 'Card'))),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bottom Bar Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: const Color(0xFFF1F4FA),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(totalAmount: total),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text("Lanjut ke Pembayaran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF007A5E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "BERANDA"),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "KASIR"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: "INVENTARIS"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "RIWAYAT"),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildPaymentButton(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007A5E) : const Color(0xFFF1F4FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 20),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
