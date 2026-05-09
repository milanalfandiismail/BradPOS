import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';

class BradHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onSettingsTap;
  final IconData leadingIcon;
  final bool showSettings;

  const BradHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.onSettingsTap,
    this.leadingIcon = Icons.storefront_rounded,
    this.showSettings = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (showBackButton)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  leadingIcon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 12),
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
                        letterSpacing: 1.0,
                      ),
                ),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
          if (showSettings)
            IconButton(
              onPressed: onSettingsTap ?? () => _showSettingsMenu(context),
              tooltip: 'Settings',
              icon: const Icon(
                Icons.settings_outlined,
                color: Color(0xFF64748B),
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    // Placeholder for settings logic or shared menu
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
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
              // Dispatch logout event if needed
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
