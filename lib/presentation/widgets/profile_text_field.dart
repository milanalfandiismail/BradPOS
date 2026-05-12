import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final IconData? icon;
  final bool readOnly;
  final bool obscureText;
  final double borderRadius;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.icon,
    this.readOnly = false,
    this.obscureText = false,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecoration(),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        obscureText: obscureText,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: readOnly ? const Color(0xFF64748B) : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: const Color(0xFF94A3B8))
              : null,
          filled: true,
          fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  BoxDecoration? boxDecoration() {
    return readOnly
        ? null
        : BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          );
  }
}
