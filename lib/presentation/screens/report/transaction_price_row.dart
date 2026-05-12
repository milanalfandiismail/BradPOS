import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bradpos/core/app_colors.dart';

class TransactionPriceRow extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat formatter;
  final bool isTotal;
  final bool isDiscount;
  final bool isLandscape;

  const TransactionPriceRow({
    super.key,
    required this.label,
    required this.value,
    required this.formatter,
    this.isTotal = false,
    this.isDiscount = false,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLandscape ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal
                  ? (isLandscape ? 14 : 18)
                  : (isLandscape ? 9 : 14),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatter.format(value),
            style: TextStyle(
              fontSize: isTotal
                  ? (isLandscape ? 14 : 18)
                  : (isLandscape ? 9 : 14),
              fontWeight: FontWeight.bold,
              color: isDiscount
                  ? Colors.red
                  : (isTotal ? AppColors.primary : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
