import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_event.dart';

Future<void> showAddStockDialog(BuildContext context, InventoryItem item) {
  final stockController = TextEditingController();
  return showDialog(
    context: context,
    builder: (dialogContext) {
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      return Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          constraints: BoxConstraints(maxWidth: isLandscape ? 380 : 400),
          padding: EdgeInsets.fromLTRB(20, isLandscape ? 6 : 20, 20, isLandscape ? 6 : 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLandscape)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tambah Stok',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                            Text(item.name,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey),
                                overflow: TextOverflow.ellipsis),
                            Text('Stok: ${item.stock} ${item.unit}',
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  labelText: 'Qty',
                                  labelStyle: TextStyle(fontSize: 10),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.redAccent, size: 18),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final qty =
                                    int.tryParse(stockController.text);
                                if (qty == null || qty <= 0) return;
                                final updatedItem = item.copyWith(
                                    stock: item.stock + qty,
                                    updatedAt: DateTime.now());
                                context.read<InventoryBloc>().add(
                                    UpdateInventoryItemEvent(updatedItem));
                                Navigator.pop(dialogContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text('OK',
                                  style: TextStyle(fontSize: 10)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tambah Stok',
                                style: TextStyle(
                                    fontSize: isLandscape ? 14 : 18,
                                    fontWeight: FontWeight.w900)),
                            Text(item.name,
                                style: TextStyle(
                                    fontSize: isLandscape ? 11 : 13,
                                    color: Colors.grey),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isLandscape ? 8 : 12),
                  Text('Stok saat ini: ${item.stock} ${item.unit}',
                      style: TextStyle(fontSize: isLandscape ? 11 : 13)),
                  SizedBox(height: isLandscape ? 8 : 12),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: TextStyle(fontSize: isLandscape ? 12 : 14),
                    decoration: InputDecoration(
                      labelText: 'Jumlah ditambahkan',
                      labelStyle: TextStyle(fontSize: isLandscape ? 11 : 13),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  SizedBox(height: isLandscape ? 12 : 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text('Batal',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: isLandscape ? 11 : 13)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final qty = int.tryParse(stockController.text);
                          if (qty == null || qty <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Masukkan jumlah yang valid')));
                            return;
                          }
                          final updatedItem = item.copyWith(
                              stock: item.stock + qty,
                              updatedAt: DateTime.now());
                          context
                              .read<InventoryBloc>()
                              .add(UpdateInventoryItemEvent(updatedItem));
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              horizontal: isLandscape ? 16 : 24,
                              vertical: isLandscape ? 8 : 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Simpan',
                            style:
                                TextStyle(fontSize: isLandscape ? 11 : 13)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
