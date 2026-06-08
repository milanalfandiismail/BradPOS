import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bradpos/core/app_colors.dart';

class FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final String? prefix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final bool isCompact;

  const FormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.prefix,
    this.keyboardType,
    this.formatters,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCompact) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          style: TextStyle(
            fontSize: isCompact ? 10 : 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: isCompact ? label : hint,
            prefixText: prefix != null ? '$prefix ' : null,
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
              child: Icon(
                icon,
                size: isCompact ? 13 : 20,
                color: AppColors.primary,
              ),
            ),
            prefixIconConstraints: isCompact
                ? const BoxConstraints(minWidth: 30, minHeight: 0)
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 16,
              vertical: isCompact ? 8 : 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 8 : 16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class FormPickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool isCompact;
  final VoidCallback onTap;

  const FormPickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCompact) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
        ],
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 16,
              vertical: isCompact ? 8 : 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(isCompact ? 8 : 16),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: isCompact ? 8 : 12),
                  child: Icon(
                    icon,
                    size: isCompact ? 13 : 20,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isCompact ? 10 : 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey,
                  size: isCompact ? 13 : 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
