import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/screens/login_screen.dart';
import 'package:bradpos/presentation/screens/dashboard_screen.dart';
import 'package:bradpos/core/sync/sync_service.dart';
import '../../injection_container.dart';
import '../app_colors.dart';
import '../utils/app_navigator.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasNavigated = false;
  bool _isProcessing = false;
  String _statusMessage = 'Menyiapkan aplikasi...';

  @override
  void initState() {
    super.initState();
    // Cek state langsung setelah frame pertama (300ms biar CheckAuthStatus sempet selesai)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), _checkAndNavigate);
    });
  }

  /// Cek current auth state dan langsung navigate.
  /// Dipanggil dari initState fallback DAN BlocListener.
  void _checkAndNavigate() {
    if (_hasNavigated || !mounted) return;
    final state = context.read<AuthBloc>().state;

    if (state is AuthAuthenticated) {
      _syncAndGo();
    } else if (state is AuthUnauthenticated || state is AuthError) {
      _goToLogin();
    }
    // AuthLoading/AuthInitial → BlocListener akan handle nanti
  }

  Future<void> _syncAndGo() async {
    if (_hasNavigated || _isProcessing) return;
    _isProcessing = true;
    if (mounted) setState(() => _statusMessage = 'Menyelaraskan data...');

    try {
      await sl<SyncService>().syncAll().timeout(
        const Duration(seconds: 3),
        onTimeout: () => debugPrint("Splash: sync timeout, lanjut"),
      );
    } catch (e) {
      debugPrint("Splash: sync error: $e");
    }

    // Fake loading biar estetik
    await Future.delayed(const Duration(seconds: 3));

    _goToDashboard();
  }

  void _goToDashboard() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    AppNavigator.pushReplacement(context, const DashboardScreen());
  }

  void _goToLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    AppNavigator.pushReplacement(context, const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget logoSection = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'BradPOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Smart Inventory System',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );

    Widget loadingSection = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _statusMessage,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _syncAndGo();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          _goToLogin();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Center(
            child: isLandscape
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [logoSection, loadingSection],
                  )
                : Stack(
                    children: [
                      Center(child: logoSection),
                      Positioned(
                        bottom: 60,
                        left: 0,
                        right: 0,
                        child: loadingSection,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
