import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/core/widgets/splash_page.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/utils/app_navigator.dart';
import 'register_screen.dart';

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
          ? _buildOwnerForm(isLandscape)
          : _buildKaryawanForm(isLandscape),
    );
  }

  // ============== OWNER FORM ==============
  Widget _buildOwnerForm(bool isLandscape) {
    return Form(
      key: _ownerFormKey,
      child: Column(
        key: const ValueKey('owner_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Input
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: isLandscape ? 13 : 16),
            decoration: InputDecoration(
              labelText: 'Email Address',
              isDense: true,
              contentPadding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : null,
              prefixIcon: Icon(Icons.email_outlined, size: isLandscape ? 18 : 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan email anda';
              }
              if (!value.contains('@')) {
                return 'Masukkan email yang valid';
              }
              return null;
            },
          ),
          SizedBox(height: isLandscape ? 8 : 20),

          // Password Input
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            style: TextStyle(fontSize: isLandscape ? 13 : 16),
            decoration: InputDecoration(
              labelText: 'Password',
              isDense: true,
              contentPadding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : null,
              prefixIcon: Icon(Icons.lock_outline, size: isLandscape ? 18 : 22),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: isLandscape ? 18 : 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            onFieldSubmitted: (_) => _onOwnerLogin(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan password anda';
              }
              return null;
            },
          ),
          SizedBox(height: isLandscape ? 12 : 28),

          // Login Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SizedBox(
                height: isLandscape ? 38 : 56,
                child: ElevatedButton(
                  onPressed: state is AuthLoading ? null : _onOwnerLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: state is AuthLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Sign In sebagai Owner',
                          style: TextStyle(
                            fontSize: isLandscape ? 13 : 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              );
            },
          ),
          SizedBox(height: isLandscape ? 8 : 20),

          // OR divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade400)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isLandscape ? 11 : 14,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade400)),
            ],
          ),
          SizedBox(height: isLandscape ? 8 : 20),

          // Google & Guest Buttons in Row for landscape
          if (isLandscape)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(GoogleSignInRequested());
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                          width: 16,
                          height: 16,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.g_mobiledata, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Google',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(ContinueAsGuestRequested());
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 16, color: AppColors.secondary),
                        SizedBox(width: 8),
                        Text(
                          'Guest',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else ...[
            // Google Login Button (Portrait)
            OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(GoogleSignInRequested());
              },
              style: OutlinedButton.styleFrom(
                fixedSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              icon: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_circle_outlined,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              label: const Text(
                'Continue with Google',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Guest / Offline Mode Button (Portrait)
            OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(ContinueAsGuestRequested());
              },
              style: OutlinedButton.styleFrom(
                fixedSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                ),
              ),
              icon: const Icon(
                Icons.wifi_off,
                size: 28,
                color: AppColors.secondary,
              ),
              label: const Text(
                'Lanjut Mode Offline (Guest)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          SizedBox(height: isLandscape ? 8 : 28),

          // Register Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Belum punya akun? ",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isLandscape ? 12 : 14,
                ),
              ),
              TextButton(
                onPressed: () {
                  AppNavigator.push(context, const RegisterScreen());
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Daftar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: isLandscape ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============== Karyawan FORM ==============
  Widget _buildKaryawanForm(bool isLandscape) {
    return Form(
      key: _karyawanFormKey,
      child: Column(
        key: const ValueKey('karyawan_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Box (Hidden in landscape to save space)
          if (!isLandscape) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.secondary, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gunakan Shop ID, Nama & Password yang diberikan oleh Owner toko anda.',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Shop ID
          TextFormField(
            controller: _shopIdController,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: isLandscape ? 13 : 16),
            decoration: InputDecoration(
              labelText: 'Shop ID',
              isDense: true,
              contentPadding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : null,
              hintText: 'Contoh: BAA-2026',
              prefixIcon: Icon(Icons.store_outlined, size: isLandscape ? 18 : 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.secondary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Masukkan Shop ID';
              }
              return null;
            },
          ),
          SizedBox(height: isLandscape ? 8 : 16),

          // Nama Karyawan
          TextFormField(
            controller: _karyawanNameController,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: isLandscape ? 13 : 16),
            decoration: InputDecoration(
              labelText: 'Nama Karyawan',
              isDense: true,
              contentPadding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : null,
              prefixIcon: Icon(Icons.badge_outlined, size: isLandscape ? 18 : 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.secondary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Masukkan nama karyawan';
              }
              return null;
            },
          ),
          SizedBox(height: isLandscape ? 8 : 20),

          // karyawan.password
          TextFormField(
            controller: _karyawanPassController,
            obscureText: _obscureKaryawanPass,
            textInputAction: TextInputAction.done,
            style: TextStyle(fontSize: isLandscape ? 13 : 16),
            decoration: InputDecoration(
              labelText: 'Password',
              isDense: true,
              contentPadding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : null,
              prefixIcon: Icon(Icons.lock_outline, size: isLandscape ? 18 : 22),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKaryawanPass
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: isLandscape ? 18 : 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscureKaryawanPass = !_obscureKaryawanPass;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.secondary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            onFieldSubmitted: (_) => _onKaryawanLogin(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan password anda';
              }
              return null;
            },
          ),
          SizedBox(height: isLandscape ? 12 : 32),

          // Karyawan Login Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SizedBox(
                height: isLandscape ? 38 : 56,
                child: ElevatedButton(
                  onPressed: state is AuthLoading ? null : _onKaryawanLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: state is AuthLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Masuk sebagai Karyawan',
                          style: TextStyle(
                            fontSize: isLandscape ? 13 : 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              );
            },
          ),
          SizedBox(height: isLandscape ? 8 : 24),

          // Help Text
          Text(
            'Hubungi Owner toko anda\njika belum memiliki akun karyawan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isLandscape ? 11 : 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
