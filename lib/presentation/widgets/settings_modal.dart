import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/screens/profile_screen.dart';
import 'package:bradpos/presentation/screens/personal_profile_screen.dart';

class SettingsModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
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
            const SizedBox(height: 24),
            const Text(
              'PENGATURAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Tab Content
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final bool isOwner = state is AuthAuthenticated && state.user.isOwner;
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOwner)
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.store_rounded,
                              color: Colors.blue.shade700, size: 20),
                        ),
                        title: const Text(
                          'Profil Bisnis',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B)),
                        ),
                        subtitle: const Text('Kelola informasi toko & akun',
                            style: TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          );
                        },
                      ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_outline_rounded,
                            color: Colors.teal.shade700, size: 20),
                      ),
                      title: const Text(
                        'Profil Saya',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B)),
                      ),
                      subtitle: const Text('Kelola informasi akun pribadi',
                          style: TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PersonalProfileScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.help_outline_rounded,
                            color: Colors.orange.shade700, size: 20),
                      ),
                      title: const Text(
                        'Bantuan',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      subtitle: const Text('Pusat bantuan & panduan',
                          style: TextStyle(fontSize: 12)),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 32, indent: 20, endIndent: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
              ),
              title: const Text(
                'Keluar Akun',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirm(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Yakin ingin keluar dari BradPOS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
