import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckoutCard extends StatelessWidget {
  final double amountReceived;
  final double balanceDue;
  final double change;
  final NumberFormat currencyFormatter;
  final bool isCompact;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CheckoutCard({
    super.key,
    required this.amountReceived,
    required this.balanceDue,
    required this.change,
    required this.currencyFormatter,
    this.isCompact = false,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canConfirm = amountReceived >= balanceDue;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 6 : 12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tagihan',
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 8 : 10,
                ),
              ),
              Text(
                currencyFormatter.format(balanceDue),
                style: TextStyle(
                  fontSize: isCompact ? 10 : 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (!isCompact) const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                change >= 0 ? 'Kembalian' : 'Kurang',
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 8 : 10,
                ),
              ),
              Text(
                currencyFormatter.format(change.abs()),
                style: TextStyle(
                  fontSize: isCompact ? 10 : 13,
                  fontWeight: FontWeight.w900,
                  color: change >= 0
                      ? const Color(0xFF059669)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 2 : 6),
          SizedBox(
            width: double.infinity,
            height: isCompact ? 20 : 36,
            child: ElevatedButton(
              onPressed: canConfirm ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
                ),
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 9 : 12,
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 2 : 4),
          SizedBox(
            width: double.infinity,
            height: isCompact ? 18 : 28,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
                ),
              ),
              child: Text(
                'Cancel Order',
                style: TextStyle(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 8 : 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
