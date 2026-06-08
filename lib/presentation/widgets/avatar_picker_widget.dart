import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bradpos/core/app_colors.dart';

/// A reusable widget that displays a circular avatar with a camera icon
/// overlay. Supports local image file, remote URL, or a default person icon
/// as fallback.
class AvatarPickerWidget extends StatelessWidget {
  final String? localImagePath;
  final String? remoteImageUrl;
  final String heroTag;
  final bool isCompact;
  final VoidCallback onTap;
  final VoidCallback onCameraTap;

  const AvatarPickerWidget({
    super.key,
    required this.localImagePath,
    required this.remoteImageUrl,
    required this.heroTag,
    required this.isCompact,
    required this.onTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocalImage =
        localImagePath != null && File(localImagePath!).existsSync();
    final hasRemoteImage =
        remoteImageUrl != null && remoteImageUrl!.isNotEmpty;

    return Center(
      child: GestureDetector(
        onTap: () {
          if (hasLocalImage || hasRemoteImage) {
            onTap();
          } else {
            onCameraTap();
          }
        },
        child: Hero(
          tag: heroTag,
          child: Stack(
            children: [
              Container(
                width: isCompact ? 80 : 100,
                height: isCompact ? 80 : 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasLocalImage
                      ? Image.file(
                          File(localImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return hasRemoteImage
                                ? CachedNetworkImage(
                                    imageUrl: remoteImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  );
                          },
                        )
                      : hasRemoteImage
                          ? CachedNetworkImage(
                              imageUrl: remoteImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onCameraTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: isCompact ? 12 : 16,
                    ),
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

/// Fallback widget displayed when no avatar image is available.
Widget buildAvatarFallback() {
  return Container(
    color: Colors.grey[200],
    child: const Icon(Icons.person, size: 100, color: Colors.grey),
  );
}
