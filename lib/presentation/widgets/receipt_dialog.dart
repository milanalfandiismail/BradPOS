import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';

class ReceiptItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  ReceiptItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}

class ReceiptDialog extends StatelessWidget {
  final List<ReceiptItem> items;
  final String shopName;
  final String customerName;
  final String cashierName;
  final double amountReceived;
  final double change;
  final String paymentMethod;
  final double total;
  final String? shopAddress;
  final String? shopPhone;
  final DateTime? date;

  const ReceiptDialog({
    super.key,
    required this.items,
    required this.shopName,
    required this.customerName,
    required this.cashierName,
    required this.amountReceived,
    required this.change,
    required this.paymentMethod,
    required this.total,
    this.shopAddress,
    this.shopPhone,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date ?? DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(shopName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (shopAddress != null)
              Text(shopAddress!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            if (shopPhone != null)
              Text('Telp: $shopPhone', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 10),
            const Divider(color: Colors.black, thickness: 1),
            _receiptInfoRow('TANGGAL', dateStr),
            _receiptInfoRow('KASIR', cashierName.toUpperCase()),
            _receiptInfoRow('PELANGGAN', customerName.toUpperCase()),
            const Divider(color: Colors.black, thickness: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.quantity} x ${currency.format(item.unitPrice)}', style: const TextStyle(fontSize: 11)),
                            Text(currency.format(item.subtotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.black, thickness: 1),
            _receiptRow('TOTAL', currency.format(total), isBold: true),
            _receiptRow('METODE', paymentMethod.toUpperCase()),
            _receiptRow('BAYAR', currency.format(amountReceived)),
            _receiptRow('KEMBALI', currency.format(change)),
            const Divider(color: Colors.black),
            const SizedBox(height: 10),
            const Text('Terima Kasih Atas Kunjungan Anda', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('TUTUP'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Logic trigger print ke hardware
                    },
                    icon: const Icon(Icons.print, size: 18, color: Colors.white),
                    label: const Text('PRINT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _receiptInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
