import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';

Widget buildFormSectionHeader(
  IconData icon,
  String title, {
  bool isCompact = false,
}) =>
    Row(
      children: [
        Icon(icon, size: isCompact ? 10 : 18, color: AppColors.primary),
        SizedBox(width: isCompact ? 3 : 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isCompact ? 9 : 11,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

Widget buildFormSectionCard(
  List<Widget> children, {
  bool isCompact = false,
}) =>
    Container(
      padding: EdgeInsets.all(isCompact ? 8 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 24),
        boxShadow: isCompact
            ? const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );

Widget buildFormSubmitButton({
  bool isCompact = false,
  bool isSubmitting = false,
  bool isEditing = false,
  VoidCallback? onSubmit,
}) =>
    Container(
      width: double.infinity,
      height: isCompact ? 32 : 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: isCompact ? 6 : 12,
            offset: Offset(0, isCompact ? 2 : 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 8 : 18),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH PRODUK',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 10 : 14,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
