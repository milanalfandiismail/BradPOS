import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';

class BradHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onSyncTap;
  final IconData leadingIcon;
  final bool showSettings;
  final bool showBottomBorder;

  const BradHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.onSettingsTap,
    this.onSyncTap,
    this.leadingIcon = Icons.storefront_rounded,
    this.showSettings = true,
    this.showBottomBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.only(
        left: showBackButton ? (isLandscape ? 0 : 4) : (isLandscape ? 12 : 20),
        right: isLandscape ? 12 : 20,
        top: isLandscape ? 4 : 0,
        bottom: isLandscape ? 4 : 0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: showBottomBorder
            ? const Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isLandscape ? 0 : 12),
        child: Row(
          children: [
            if (showBackButton)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(isLandscape ? 4 : 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: isLandscape ? 14 : 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            Container(
              width: isLandscape ? 20 : 40,
              height: isLandscape ? 20 : 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  leadingIcon,
                  color: AppColors.primary,
                  size: isLandscape ? 15 : 20,
                ),
              ),
            ),
            SizedBox(width: isLandscape ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subtitle.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontSize: isLandscape ? 6 : null,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      fontSize: isLandscape ? 10 : null,
                    ),
                  ),
                ],
              ),
            ),
            if (actions != null) ...actions!,
            if (onSyncTap != null && !isLandscape)
              IconButton(
                onPressed: onSyncTap,
                tooltip: 'Sync',
                padding: const EdgeInsets.all(8),
                icon: const Icon(
                  Icons.sync_rounded,
                  color: Color(0xFF64748B),
                  size: 24,
                ),
              ),
            if (showSettings && !isLandscape)
              IconButton(
                onPressed: onSettingsTap ?? () => _showSettingsMenu(context),
                tooltip: 'Settings',
                padding: isLandscape ? EdgeInsets.zero : const EdgeInsets.all(8),
                constraints: isLandscape
                    ? const BoxConstraints(minWidth: 32, minHeight: 32)
                    : null,
                icon: Icon(
                  Icons.settings_outlined,
                  color: const Color(0xFF64748B),
                  size: isLandscape ? 18 : 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profil Saya'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Bantuan'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
