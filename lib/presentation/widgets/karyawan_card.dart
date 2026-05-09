import 'package:flutter/material.dart';
import 'package:bradpos/domain/entities/karyawan.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:ui';

/// Widget Card untuk menampilkan ringkasan data Karyawan.
/// Digunakan di KaryawanListScreen.
class KaryawanCard extends StatelessWidget {
  final Karyawan karyawan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const KaryawanCard({
    super.key,
    required this.karyawan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showFullScreenImage(context),
                child: Hero(
                  tag: 'karyawan_avatar_${karyawan.id}',
                  child: ClipOval(
                    child: Container(
                      width: 56,
                      height: 56,
                      color: const Color(0xFFF1F5F9),
                      child: _buildImage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ID: #${karyawan.id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        _buildStatusBadge(karyawan.isActive),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      karyawan.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Karyawan Aktif',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Ubah'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF475569),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Menampilkan tag status AKTIF/NONAKTIF dengan warna yang berbeda.
  Widget _buildStatusBadge(bool isActive) {
    Color bgColor;
    Color textColor;
    String label;

    if (isActive) {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
      label = 'AKTIF';
    } else {
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF991B1B);
      label = 'NONAKTIF';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: karyawan.name,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            karyawan.name,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
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
                tag: 'karyawan_avatar_${karyawan.id}',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipOval(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: _buildImage(isFullScreen: true),
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

  Widget _buildImage({bool isFullScreen = false}) {
    if (karyawan.localImage != null && karyawan.localImage!.isNotEmpty) {
      final file = File(karyawan.localImage!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildRemoteOrPlaceholder(isFullScreen),
        );
      }
    }

    return _buildRemoteOrPlaceholder(isFullScreen);
  }

  Widget _buildRemoteOrPlaceholder(bool isFullScreen) {
    if (karyawan.remoteImage != null && karyawan.remoteImage!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: karyawan.remoteImage!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.person,
          size: isFullScreen ? 100 : 20,
          color: Colors.grey,
        ),
      );
    }

    return Icon(
      Icons.person,
      size: isFullScreen ? 100 : 20,
      color: Colors.grey,
    );
  }
}
