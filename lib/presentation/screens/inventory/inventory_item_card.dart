import 'package:flutter/material.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_item_card_shared.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_item_card_compact.dart';
import 'package:bradpos/presentation/screens/inventory/inventory_item_card_normal.dart';

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

  StatusData _getStatusData() {
    if (item.stock == -1) {
      return const StatusData('UNLIMITED', Color(0xFF0369A1), Color(0xFFE0F2FE));
    }
    if (item.stock == 0) {
      return const StatusData('OUT OF STOCK', Color(0xFFEF4444), Color(0xFFFEE2E2));
    }
    if (item.stock <= 10) {
      return const StatusData('LOW STOCK', Color(0xFFF59E0B), Color(0xFFFEF3C7));
    }
    return const StatusData('STABLE', Color(0xFF10B981), Color(0xFFD1FAE5));
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatusData();
    final isUnlimited = item.stock == -1;

    if (isCompact) {
      return InventoryItemCardCompact(
        item: item,
        status: status,
        isUnlimited: isUnlimited,
        isKaryawan: isKaryawan,
        onEdit: onEdit,
        onDelete: onDelete,
        onAddStock: onAddStock,
        onReduceStock: onReduceStock,
      );
    }
    return InventoryItemCardNormal(
      item: item,
      status: status,
      isUnlimited: isUnlimited,
      isKaryawan: isKaryawan,
      onEdit: onEdit,
      onDelete: onDelete,
      onAddStock: onAddStock,
      onReduceStock: onReduceStock,
    );
  }
}
