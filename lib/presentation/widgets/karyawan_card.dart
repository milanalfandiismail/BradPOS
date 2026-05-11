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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isLandscape ? 8 : 12),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showFullScreenImage(context),
                child: Hero(
                  tag: 'karyawan_avatar_${karyawan.id}',
                  child: ClipOval(
                    child: Container(
                      width: isLandscape ? 40 : 56,
                      height: isLandscape ? 40 : 56,
                      color: const Color(0xFFF1F5F9),
                      child: _buildImage(),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isLandscape ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                                fontSize: isLandscape ? 8 : null,
                              ),
                        ),
                        _buildStatusBadge(karyawan.isActive, isCompact: isLandscape),
                      ],
                    ),
                    SizedBox(height: isLandscape ? 0 : 2),
                    Text(
                      karyawan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (isLandscape 
                          ? Theme.of(context).textTheme.titleSmall 
                          : Theme.of(context).textTheme.titleMedium)?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (!isLandscape) ...[
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
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isLandscape ? 8 : 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: isLandscape ? 32 : 40,
                  child: FilledButton.tonalIcon(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_rounded, size: isLandscape ? 14 : 18),
                    label: Text('Ubah', style: TextStyle(fontSize: isLandscape ? 11 : 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF475569),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: isLandscape ? 32 : 40,
                width: isLandscape ? 32 : 40,
                child: IconButton.filledTonal(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, size: isLandscape ? 16 : 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFEF4444),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
  Widget _buildStatusBadge(bool isActive, {bool isCompact = false}) {
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
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8, 
        vertical: isCompact ? 2 : 4
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isCompact ? 8 : 10,
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
