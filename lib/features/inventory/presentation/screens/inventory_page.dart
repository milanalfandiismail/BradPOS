import 'package:bradpos/features/inventory/presentation/screens/edit_item_page.dart';
import 'package:bradpos/features/settings/presentation/screens/settings_page.dart';
import 'package:flutter/material.dart';

class InventoryProduct {
  final String sku;
  final String name;
  final int stock;
  final String status;
  final Color statusColor;
  final Color statusTextColor;

  InventoryProduct({
    required this.sku,
    required this.name,
    required this.stock,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
  });
}

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<InventoryProduct> products = [
      InventoryProduct(
        sku: "SKU: AUD-9920",
        name: "Premium Wireless Audio",
        stock: 3,
        status: "STOK TIPIS",
        statusColor: const Color(0xFFFEE2E2),
        statusTextColor: const Color(0xFFB91C1C),
      ),
      InventoryProduct(
        sku: "SKU: WTC-4401",
        name: "Sport Connect V2",
        stock: 48,
        status: "STABIL",
        statusColor: const Color(0xFFD1FAE5),
        statusTextColor: const Color(0xFF065F46),
      ),
      InventoryProduct(
        sku: "SKU: SHD-1011",
        name: "Nitro Runner Max",
        stock: 0,
        status: "STOK HABIS",
        statusColor: const Color(0xFFFFEDD5),
        statusTextColor: const Color(0xFF9A3412),
      ),
      InventoryProduct(
        sku: "SKU: CAM-5520",
        name: "Classic View Mirrorless",
        stock: 12,
        status: "STABIL",
        statusColor: const Color(0xFFD1FAE5),
        statusTextColor: const Color(0xFF065F46),
      ),
    ];

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              "Manajemen Inventaris",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1D1E),
              ),
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari produk berdasarkan nama atau SKU...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F4FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filters and New Product
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text("Filter"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A5568),
                      backgroundColor: const Color(0xFFE8EEF9),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Produk Baru"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A5E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Inventory List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _InventoryCard(product: product);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryProduct product;

  const _InventoryCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.sku,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.status,
                            style: TextStyle(
                              color: product.statusTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${product.stock.toString().padLeft(2, '0')} ",
                            style: TextStyle(
                              color: product.stock <= 5 ? Colors.red : const Color(0xFF007A5E),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const TextSpan(
                            text: "unit tersisa",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditItemPage()),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text("Edit Produk"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4A5568),
                backgroundColor: const Color(0xFFF1F4FA),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
