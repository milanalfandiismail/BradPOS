import 'package:flutter/material.dart';

class CustomerCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isCompact;

  const CustomerCard({
    super.key,
    required this.controller,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 12,
        vertical: isCompact ? 2 : 12,
      ),
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
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: isCompact ? 12 : 22,
            color: const Color(0xFF64748B),
          ),
          SizedBox(width: isCompact ? 3 : 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Nama Pelanggan',
                hintStyle: TextStyle(
                  fontSize: isCompact ? 8 : 13,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: isCompact ? 9 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
