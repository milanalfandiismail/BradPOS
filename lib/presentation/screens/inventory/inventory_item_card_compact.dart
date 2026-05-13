import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io' as io;
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_item_card_shared.dart';

class InventoryItemCardCompact extends StatelessWidget {
  final InventoryItem item;
  final StatusData status;
  final bool isUnlimited;
  final bool isKaryawan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAddStock;
  final VoidCallback? onReduceStock;

  const InventoryItemCardCompact({
    super.key,
    required this.item,
    required this.status,
    required this.isUnlimited,
    required this.isKaryawan,
    required this.onEdit,
    required this.onDelete,
    this.onAddStock,
    this.onReduceStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 50,
                  height: 50,
                  color: const Color(0xFFF8FAFC),
                  child: _buildImage(item.imageUrl),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              item.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildStatusBadge(status.label, status.color, status.bgColor, isCompact: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (!isUnlimited)
                      Row(
                        children: [
                          Text(
                            item.stock.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: status.color,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.unit,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'No stock tracking',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          if (!isUnlimited && !isKaryawan) ...[
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    label: 'Tambah',
                    icon: Icons.add,
                    bg: const Color(0xFF065F46),
                    fg: Colors.white,
                    onTap: onAddStock,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildButton(
                    label: 'Kurang',
                    icon: Icons.remove,
                    bg: const Color(0xFFEF4444),
                    fg: Colors.white,
                    onTap: onReduceStock,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (!isKaryawan)
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF334155),
                    borderColor: const Color(0xFFE2E8F0),
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildButton(
                    label: 'Hapus',
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    borderColor: const Color(0xFFFEE2E2),
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    Color? color,
    Color? borderColor,
    Color? bg,
    Color? fg,
    required VoidCallback? onTap,
  }) {
    if (borderColor != null) {
      return SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 14, color: color),
          label: Text(label, style: TextStyle(fontSize: 10, color: color)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 26,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(0, 26),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color, Color bg, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isCompact ? 9 : 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF94A3B8),
        size: 24,
      );
    }

    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    }
    return Image.file(
      io.File(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
    );
  }
}
