import 'package:flutter/material.dart';

class TransactionInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;
  final bool isLandscape;

  const TransactionInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isStatus = false,
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
              color: Colors.grey,
              fontSize: isLandscape ? 9 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isLandscape ? 9 : 14,
              color: isStatus ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
