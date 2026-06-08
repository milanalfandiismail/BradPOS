import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/domain/entities/inventory_item.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_event.dart';

Future<void> showReduceStockDialog(BuildContext context, InventoryItem item) {
  final stockController = TextEditingController();
  return showDialog(
    context: context,
    builder: (dialogContext) {
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      return Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isLandscape ? 12 : 20)),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(isLandscape ? 12 : 20)),
          constraints: BoxConstraints(maxWidth: isLandscape ? 380 : 400),
          padding: EdgeInsets.fromLTRB(isLandscape ? 12 : 24, isLandscape ? 8 : 20, isLandscape ? 12 : 24, isLandscape ? 8 : 16),
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
                            Text('Kurangi Stok',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900)),
                            Text(item.name,
                                style: TextStyle(
                                    fontSize: 9, color: Colors.grey),
                                overflow: TextOverflow.ellipsis),
                            Text('Stok: ${item.stock} ${item.unit}',
                                style: const TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                style: const TextStyle(fontSize: 10),
                                decoration: const InputDecoration(
                                  labelText: 'Qty',
                                  labelStyle: TextStyle(fontSize: 9),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.redAccent, size: 16),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final qty =
                                    int.tryParse(stockController.text);
                                if (qty == null || qty <= 0) return;
                                if (qty > item.stock) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content:
                                              Text('Stok tidak mencukupi')));
                                  return;
                                }
                                final updatedItem = item.copyWith(
                                    stock: item.stock - qty,
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
                                    horizontal: 8),
                                minimumSize: const Size(0, 26),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              child: const Text('OK',
                                  style: TextStyle(fontSize: 9)),
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
                            Text('Kurangi Stok',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                            Text(item.name,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Stok saat ini: ${item.stock} ${item.unit}',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Jumlah dikurangi',
                      labelStyle: TextStyle(fontSize: 13),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Batal',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13)),
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
                          if (qty > item.stock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Stok tidak mencukupi')));
                            return;
                          }
                          final updatedItem = item.copyWith(
                              stock: item.stock - qty,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Simpan',
                            style:
                                TextStyle(fontSize: 13)),
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
