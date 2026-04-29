import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../core/sync/sync_service.dart';
import '../../injection_container.dart';
import '../app_colors.dart';

class SplashPage extends StatefulWidget {
  final UserEntity? user;
  const SplashPage({super.key, this.user});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _syncAndGo();
    } else {
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    context.read<AuthBloc>().add(CheckAuthStatus());
  }

  Future<void> _syncAndGo() async {
    setState(() => _isSyncing = true);
    final syncService = sl<SyncService>();
    await syncService.syncAll();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _syncAndGo();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau Nama Aplikasi
              const Text(
                'BradPOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                _isSyncing ? 'Menyelaraskan data...' : 'Menyiapkan aplikasi...',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
