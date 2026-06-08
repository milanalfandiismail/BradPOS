import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/core/widgets/splash_page.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/utils/app_navigator.dart';
import 'package:bradpos/presentation/screens/login/login_owner_form.dart';
import 'package:bradpos/presentation/screens/login/login_karyawan_form.dart';

/// Halaman Login utama BradPOS.
/// Terdapat 2 tab: Login sebagai Owner dan Login sebagai Karyawan.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopIdController = TextEditingController();
  final _karyawanNameController = TextEditingController();
  final _karyawanPassController = TextEditingController();
  final _ownerFormKey = GlobalKey<FormState>();
  final _karyawanFormKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureKaryawanPass = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shopIdController.dispose();
    _karyawanNameController.dispose();
    _karyawanPassController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onOwnerLogin() {
    if (_ownerFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        SignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _onKaryawanLogin() {
    if (_karyawanFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        SignInAsKaryawanRequested(
          shopId: _shopIdController.text.trim().toUpperCase(),
          name: _karyawanNameController.text.trim(),
          password: _karyawanPassController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppNavigator.pushReplacement(context, const SplashPage());
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 32.0 : 24.0,
              vertical: isLandscape ? 16.0 : 24.0,
            ),
            child: isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Side: Logo & Welcome
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'BradPOS',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Masuk ke akun anda',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Right Side: Tabs & Form
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTabBar(isLandscape),
                            const SizedBox(height: 12),
                            _buildTabContent(isLandscape),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(isLandscape),
                      const SizedBox(height: 32),
                      _buildTabBar(isLandscape),
                      const SizedBox(height: 28),
                      _buildTabContent(isLandscape),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLandscape) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(isLandscape ? 12 : 20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront,
              size: isLandscape ? 32 : 64,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: isLandscape ? 12 : 24),
        Text(
          'Welcome to BradPOS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isLandscape ? 20 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isLandscape ? 4 : 8),
        Text(
          'Masuk sebagai Owner atau Karyawan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isLandscape ? 12 : 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isLandscape) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isLandscape ? 12 : 15,
        ),
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(
            height: isLandscape ? 32 : 46,
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings, size: 18),
                  SizedBox(width: 6),
                  Text('Owner'),
                ],
              ),
            ),
          ),
          Tab(
            height: isLandscape ? 32 : 46,
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge, size: 18),
                  SizedBox(width: 6),
                  Text('Karyawan'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isLandscape) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _tabController.index == 0
          ? LoginOwnerForm(
              key: const ValueKey('owner_form'),
              emailController: _emailController,
              passwordController: _passwordController,
              formKey: _ownerFormKey,
              obscurePassword: _obscurePassword,
              isLandscape: isLandscape,
              onToggleObscurePassword: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              onLogin: _onOwnerLogin,
            )
          : LoginKaryawanForm(
              key: const ValueKey('karyawan_form'),
              shopIdController: _shopIdController,
              karyawanNameController: _karyawanNameController,
              karyawanPassController: _karyawanPassController,
              formKey: _karyawanFormKey,
              obscurePassword: _obscureKaryawanPass,
              isLandscape: isLandscape,
              onToggleObscurePassword: () {
                setState(() {
                  _obscureKaryawanPass = !_obscureKaryawanPass;
                });
              },
              onLogin: _onKaryawanLogin,
            ),
    );
  }

}
