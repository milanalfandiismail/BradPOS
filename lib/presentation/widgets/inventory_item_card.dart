import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io' as io;
import 'package:bradpos/domain/entities/inventory_item.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAddStock;
  final VoidCallback? onReduceStock;
  final bool isKaryawan;
  final bool isCompact;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.onAddStock,
    this.onReduceStock,
    this.isKaryawan = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Logika Status Stok
    String statusLabel = 'STABLE';
    Color statusColor = const Color(0xFF10B981); // Hijau
    Color statusBg = const Color(0xFFD1FAE5);

    final isUnlimited = item.stock == -1;

    if (isUnlimited) {
      statusLabel = 'UNLIMITED';
      statusColor = const Color(0xFF0369A1); // Biru
      statusBg = const Color(0xFFE0F2FE);
    } else if (item.stock == 0) {
      statusLabel = 'OUT OF STOCK';
      statusColor = const Color(0xFFEF4444); // Merah
      statusBg = const Color(0xFFFEE2E2);
    } else if (item.stock <= 10) {
      statusLabel = 'LOW STOCK';
      statusColor = const Color(0xFFF59E0B); // Kuning/Orange
      statusBg = const Color(0xFFFEF3C7);
    }

    if (isCompact) {
      return _buildCompactCard(statusLabel, statusColor, statusBg, isUnlimited);
    }

    return _buildNormalCard(statusLabel, statusColor, statusBg, isUnlimited);
  }

  // ── Compact card for landscape grid (fixed height ~175px) ──────────────────
  Widget _buildCompactCard(
    String statusLabel,
    Color statusColor,
    Color statusBg,
    bool isUnlimited,
  ) {
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
          // Row: image + category + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
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
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (!isUnlimited)
                      Row(
                        children: [
                          Text(
                            item.stock.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.unit,
                              style: const TextStyle(
                                fontSize: 9,
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
                          fontSize: 9,
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
          // Tombol tambah/kurang
          if (!isUnlimited) ...[
            Row(
              children: [
                Expanded(
                  child: _compactBtn(
                    label: 'Tambah',
                    icon: Icons.add,
                    bg: const Color(0xFF065F46),
                    fg: Colors.white,
                    onTap: onAddStock,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _compactBtn(
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
          // Tombol edit/hapus
          if (!isKaryawan)
            Row(
              children: [
                Expanded(
                  child: _compactOutlineBtn(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF334155),
                    borderColor: const Color(0xFFE2E8F0),
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _compactOutlineBtn(
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

  Widget _compactBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
  }) => SizedBox(
    height: 22,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 10),
      label: Text(label, style: const TextStyle(fontSize: 8)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        minimumSize: const Size(0, 22),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        elevation: 0,
      ),
    ),
  );

  Widget _compactOutlineBtn({
    required String label,
    required IconData icon,
    required Color color,
    required Color borderColor,
    VoidCallback? onTap,
  }) => SizedBox(
    height: 22,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 10, color: color),
      label: Text(label, style: TextStyle(fontSize: 8, color: color)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        minimumSize: const Size(0, 22),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    ),
  );

  // ── Normal card for portrait list ──────────────────────────────────────────
  Widget _buildNormalCard(
    String statusLabel,
    Color statusColor,
    Color statusBg,
    bool isUnlimited,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImage(item.imageUrl),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (!isUnlimited)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              item.stock.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${item.unit} remaining',
                                style: const TextStyle(
                                  fontSize: 14,
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
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUnlimited)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAddStock,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Tambah',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF065F46),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onReduceStock,
                          icon: const Icon(Icons.remove, size: 18),
                          label: const Text(
                            'Kurang',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (!isUnlimited) const SizedBox(height: 8),
                if (!isKaryawan)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          label: const Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFFFEE2E2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
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
    } else {
      return Image.file(
        io.File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      );
    }
  }
}
