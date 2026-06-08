import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/screens/profile/profile_screen.dart';
import 'package:bradpos/presentation/screens/profile/personal_profile_screen.dart';

class SettingsModal {
  static void show(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      _showSidePanel(context);
    } else {
      _showBottomSheet(context);
    }
  }

  static void _showSidePanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
              ),
              child: SafeArea(
                child: _buildContent(context, isLandscape: true),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  static void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: _buildContent(context, isLandscape: false),
        ),
      ),
    );
  }

  static Widget _buildContent(BuildContext context, {required bool isLandscape}) {
    final double titleSize = isLandscape ? 10 : 12;
    final double labelSize = isLandscape ? 13 : 14;
    final double subLabelSize = isLandscape ? 10 : 12;

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(height: isLandscape ? 8 : 12),
        if (!isLandscape)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        SizedBox(height: isLandscape ? 12 : 24),
        Text(
          'PENGATURAN',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF64748B),
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: isLandscape ? 8 : 16),
        Expanded(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final bool isOwner =
                  state is AuthAuthenticated && state.user.isOwner;
              final bool isGuest =
                  state is AuthAuthenticated && state.user.isGuest;

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        if (isOwner || isGuest)
                          ListTile(
                            dense: isLandscape,
                            visualDensity: isLandscape
                                ? VisualDensity.compact
                                : VisualDensity.standard,
                            leading: _buildIcon(Icons.store_rounded, Colors.blue,
                                isLandscape: isLandscape),
                            title: Text('Profil Bisnis',
                                style: TextStyle(
                                    fontSize: labelSize,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B))),
                            subtitle: Text('Kelola informasi toko & akun',
                                style: TextStyle(fontSize: subLabelSize)),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const ProfileScreen()));
                            },
                          ),
                        if (state is AuthAuthenticated)
                          ListTile(
                            dense: isLandscape,
                            visualDensity: isLandscape
                                ? VisualDensity.compact
                                : VisualDensity.standard,
                            leading: _buildIcon(
                                Icons.person_outline_rounded, Colors.teal,
                                isLandscape: isLandscape),
                            title: Text('Profil Saya',
                                style: TextStyle(
                                    fontSize: labelSize,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B))),
                            subtitle: Text('Kelola informasi akun pribadi',
                                style: TextStyle(fontSize: subLabelSize)),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const PersonalProfileScreen()));
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  ListTile(
                    dense: isLandscape,
                    visualDensity: isLandscape
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    leading: _buildIcon(Icons.logout_rounded, Colors.red,
                        isLandscape: isLandscape),
                    title: Text('Keluar Akun',
                        style: TextStyle(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirm(context);
                    },
                  ),
                  SizedBox(height: isLandscape ? 4 : 8),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildIcon(IconData icon, MaterialColor color,
      {required bool isLandscape}) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 6 : 8),
      decoration: BoxDecoration(
        color: color.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color.shade700, size: isLandscape ? 16 : 20),
    );
  }

  static void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('Yakin ingin keluar dari BradPOS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(SignOutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
