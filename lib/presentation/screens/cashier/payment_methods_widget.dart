import 'package:flutter/material.dart';

class PaymentMethodsWidget extends StatelessWidget {
  final String selectedMethod;
  final bool isCompact;
  final ValueChanged<String> onMethodChanged;

  const PaymentMethodsWidget({
    super.key,
    required this.selectedMethod,
    this.isCompact = false,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 4 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 6 : 12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Row(
        children: [
          _methodCard('Cash', Icons.payments_outlined),
          SizedBox(width: isCompact ? 4 : 8),
          _methodCard('QRIS', Icons.qr_code_rounded),
        ],
      ),
    );
  }

  Widget _methodCard(String label, IconData icon) {
    final isSelected = selectedMethod == label;
    return Expanded(
      child: InkWell(
        onTap: () => onMethodChanged(label),
        child: Container(
          height: isCompact ? 24 : 36,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF059669)
                    : const Color(0xFF475569),
                size: isCompact ? 11 : 16,
              ),
              SizedBox(width: isCompact ? 2 : 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isCompact ? 8 : 13,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? const Color(0xFF065F46)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
