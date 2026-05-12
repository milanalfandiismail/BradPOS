import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenImageViewer {
  static Future<void> show({
    required BuildContext context,
    required String? localImagePath,
    required String? remoteImageUrl,
    required String heroTag,
    String? title,
    VoidCallback? onEdit,
  }) {
    return showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: title != null
              ? Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          actions: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipOval(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: (localImagePath != null && File(localImagePath).existsSync())
                          ? Image.file(
                              File(localImagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallback(),
                            )
                          : remoteImageUrl != null && remoteImageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: remoteImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      _buildFallback(),
                                )
                              : _buildFallback(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFallback() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, color: Color(0xFF94A3B8), size: 64),
    );
  }
}
