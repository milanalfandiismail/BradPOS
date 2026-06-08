import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';

class CashierProductCard extends StatelessWidget {
  final InventoryItem product;
  final int qty;
  final bool isGuest;
  final bool isCompact;
  final NumberFormat currencyFormatter;
  final ValueChanged<InventoryItem> onAddToCart;
  final void Function(InventoryItem, int) onUpdateQuantity;
  final VoidCallback? onShowSnackbar;

  const CashierProductCard({
    super.key,
    required this.product,
    required this.qty,
    required this.isGuest,
    required this.isCompact,
    required this.currencyFormatter,
    required this.onAddToCart,
    required this.onUpdateQuantity,
    this.onShowSnackbar,
  });

  @override
  Widget build(BuildContext context) {
    final trackStock = product.stock != -1;
    final isOutOfStock = trackStock && product.stock <= 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 20),
        border: Border.all(
          color: qty > 0 ? const Color(0xFF065F46) : const Color(0xFFCBD5E1),
          width: qty > 0 ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isCompact ? 3 : 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(isCompact ? 7 : 18),
                  ),
                  child: ColorFiltered(
                    colorFilter: isOutOfStock
                        ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                        : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: _buildImage(product),
                  ),
                ),
                if (qty > 0)
                  Positioned(
                    top: isCompact ? 3 : 8,
                    left: isCompact ? 3 : 8,
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 3 : 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF065F46),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$qty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 8 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (trackStock)
                  Positioned(
                    top: isCompact ? 3 : 8,
                    right: isCompact ? 3 : 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(isCompact ? 4 : 10),
                      ),
                      child: Text(
                        isOutOfStock ? 'HABIS' : 'STOK: ${product.stock}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 6 : 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 4.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  currencyFormatter.format(product.sellingPrice),
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 12),
                _buildQuantityBar(context, trackStock),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBar(BuildContext context, bool trackStock) {
    if (qty == 0) {
      final canAdd = !trackStock || product.stock > 0;
      return SizedBox(
        width: double.infinity,
        height: 36,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF065F46),
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isCompact ? 4 : 10),
            ),
          ),
          onPressed: canAdd ? () => onAddToCart(product) : null,
          child: Text(
            canAdd ? 'TAMBAH' : 'OUT',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _qBtn(Icons.remove, () => onUpdateQuantity(product, -1), Colors.redAccent),
          Text(
            '$qty',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          _qBtn(Icons.add, () {
            if (!trackStock || qty < product.stock) {
              onAddToCart(product);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stok tidak mencukupi!'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          }, const Color(0xFF065F46)),
        ],
      ),
    );
  }

  Widget _qBtn(IconData icon, VoidCallback onTap, Color color) {
    return SizedBox(
      width: 40,
      height: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(child: Icon(icon, color: color, size: 18)),
        ),
      ),
    );
  }

  Widget _buildImage(InventoryItem product) {
    final imageUrl = (product.imageUrl != null && product.imageUrl!.isNotEmpty)
        ? product.imageUrl!
        : '';

    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _buildFallbackImage(product),
      );
    } else if (imageUrl.isNotEmpty) {
      final file = io.File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    return _buildFallbackImage(product);
  }

  Widget _buildFallbackImage(InventoryItem product) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fastfood_rounded,
                color: const Color(0xFF64748B),
                size: isCompact ? 16 : 40,
              ),
              if (!isCompact) const SizedBox(height: 8),
              if (!isCompact)
                Text(
                  product.name.isNotEmpty
                      ? product.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
