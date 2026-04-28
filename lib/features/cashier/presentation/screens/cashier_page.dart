import 'package:bradpos/features/cashier/presentation/screens/cart_page.dart';
import 'package:bradpos/features/settings/presentation/screens/settings_page.dart';
import 'package:flutter/material.dart';

class Product {
  final String name;
  final String price;
  final String? label;
  final Color? labelColor;
  final String? imagePath; // Tambahkan ini jika ingin pakai gambar

  Product({
    required this.name,
    required this.price,
    this.label,
    this.labelColor,
    this.imagePath,
  });
}

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final List<Product> products = [
    Product(
      name: "Classic Iced Latte", 
      price: "Rp 45.000", 
      label: "Populer", 
      labelColor: const Color(0xFF007A5E),
      imagePath: "assets/images/mio.jpg", // <--- ganti gambar disini gusi
    ),

    Product(name: "Blueberry Muffin",
            price: "Rp 32.500"),

    Product(name: "Avocado Smash",
            price: "Rp 120.000"),

    Product(name: "Ceremonial Matcha",
            price: "Rp 57.500"),

    Product(name: "Margherita Slice",
            price: "Rp 60.000",
            label: "STOK TIPIS",
            labelColor: Colors.red[700]),

    Product(name: "Fresh OJ",
            price: "Rp 40.000"),

    Product(name: "Butter Croissant",
            price: "Rp 35.000"),

    Product(name: "Garden Power Bowl",
            price: "Rp 115.000"),

    Product(name: "Red Velvet Cupcake",
            price: "Rp 42.500"),

    Product(name: "The Signature Burger",
            price: "Rp 140.000"),
  ];

  int selectedCategoryIndex = 0;
  final List<String> categories = ["Semua Item", "Makanan", "Minuman", "Camilan"];

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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari produk, SKU, atau barcode...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),

          // Categories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => selectedCategoryIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF007A5E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductCard(product: product);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        alignment: Alignment.topRight,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
            backgroundColor: const Color(0xFF007A5E),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: const Text(
              "3",
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder Section
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    // =========================================================
                    // TEMPAT MENGGANTI GAMBAR:
                    // Jika ingin menggunakan gambar dari Asset, buka komentar di bawah:
                    image: product.imagePath != null ? DecorationImage(
                       image: AssetImage(product.imagePath!),
                       fit: BoxFit.cover,
                     ) : null,
                    // =========================================================
                  ),
                  width: double.infinity,
                  // Tampilkan Ikon jika imagePath kosong
                  child: product.imagePath == null 
                    ? Icon(Icons.image_outlined, color: Colors.grey[400], size: 40)
                    : null,
                ),
                if (product.label != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.labelColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.label!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Details Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1D1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A5E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
