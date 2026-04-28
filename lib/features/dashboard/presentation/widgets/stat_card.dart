import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Ukuran layarnya
    double screenWidth = MediaQuery.of(context).size.width;

    // Hitung lebar kartu (hampir setengah layar dikurangi padding)
    double cardWidth = (screenWidth - 48 - 16) / 2;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1D2B), // Warna kartu gelap (SAMA DENGAN GAMBAR)
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // BAGIAN IKON (SEBELAH KIRI)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D303E), // Background ikon gelap
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),

          // BAGIAN TEKS (SEBELAH KANAN)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Biar pas di tengah vertikal
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70, // Putih agak transparan
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1, // Hindari teks turun baris
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white, // Putih terang
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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