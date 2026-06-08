import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bradpos/core/app_colors.dart';

class InventoryFormImagePicker extends StatelessWidget {
  final String? imagePath;
  final bool isCompact;
  final VoidCallback onPickImage;

  const InventoryFormImagePicker({
    super.key,
    this.imagePath,
    this.isCompact = false,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 4 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: GestureDetector(
          onTap: onPickImage,
          child: Container(
            width: isCompact ? 50 : 120,
            height: isCompact ? 50 : 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(isCompact ? 8 : 24),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isCompact ? 8 : 22),
              child: imagePath != null
                  ? (imagePath!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imagePath!,
                          fit: BoxFit.cover,
                        )
                      : Image.file(File(imagePath!), fit: BoxFit.cover))
                  : Icon(
                      Icons.add_a_photo_rounded,
                      size: isCompact ? 18 : 28,
                      color: AppColors.primary.withAlpha(100),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
