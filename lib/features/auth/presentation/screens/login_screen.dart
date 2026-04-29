import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_colors.dart';
import '../bloc/auth_bloc.dart';
import 'register_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

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
  final _karyawanIdController = TextEditingController();
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
    _karyawanIdController.dispose();
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
          email: _karyawanIdController.text.trim(),
          password: _karyawanPassController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Welcome Text
                  const Text(
                    'Welcome to BradPOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk sebagai Owner atau Karyawan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tab Bar (Owner / Karyawan)
                  Container(
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
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.admin_panel_settings, size: 20),
                              SizedBox(width: 8),
                              Text('Owner'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.badge, size: 20),
                              SizedBox(width: 8),
                              Text('Karyawan'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tab Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _tabController.index == 0
                        ? _buildOwnerForm()
                        : _buildKaryawanForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============== OWNER FORM ==============
  Widget _buildOwnerForm() {
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
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
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
          const SizedBox(height: 20),

          // Password Input
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
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
          const SizedBox(height: 28),

          // Login Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SizedBox(
                height: 56,
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
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Sign In sebagai Owner',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // OR divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade400)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 20),

          // Google Login Button
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

          // Guest / Offline Mode Button
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
          const SizedBox(height: 28),

          // Register Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Belum punya akun? ",
                style: TextStyle(color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  'Daftar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
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
  Widget _buildKaryawanForm() {
    return Form(
      key: _karyawanFormKey,
      child: Column(
        key: const ValueKey('karyawan_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Box
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
                    'Gunakan Email & Password yang diberikan oleh Owner toko anda.',
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

          // karyawan.email
          TextFormField(
            controller: _karyawanIdController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Email Karyawan',
              prefixIcon: const Icon(Icons.badge_outlined),
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
              if (value == null || value.isEmpty) {
                return 'Masukkan email karyawan';
              }
              if (!value.contains('@')) {
                return 'Masukkan email yang valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // karyawan.password
          TextFormField(
            controller: _karyawanPassController,
            obscureText: _obscureKaryawanPass,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKaryawanPass
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.textSecondary,
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
          const SizedBox(height: 32),

          // Karyawan Login Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SizedBox(
                height: 56,
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
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Masuk sebagai Karyawan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Help Text
          const Text(
            'Hubungi Owner toko anda\njika belum memiliki akun karyawan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
