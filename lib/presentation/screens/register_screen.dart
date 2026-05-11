import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/core/widgets/splash_page.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/utils/app_navigator.dart';

/// Halaman Registrasi akun Owner baru.
/// Hanya untuk Owner - Karyawan didaftarkan oleh Owner melalui menu Karyawan.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        SignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isLandscape ? 32 : 56,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: isLandscape ? 18 : 24,
          ),
          onPressed: () => AppNavigator.pop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppNavigator.pushAndRemoveUntil(context, const SplashPage());
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
                      // Left Side: Title
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isLandscape ? 20 : 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join BradPOS and manage your store',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isLandscape ? 12 : 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Right Side: Form
                      Expanded(
                        flex: 3,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFormFields(isLandscape),
                              const SizedBox(height: 12),
                              _buildRegisterButton(isLandscape),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isLandscape),
                        const SizedBox(height: 32),
                        _buildFormFields(isLandscape),
                        const SizedBox(height: 32),
                        _buildRegisterButton(isLandscape),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLandscape) {
    return Column(
      children: [
        Text(
          'Create Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isLandscape ? 20 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isLandscape ? 4 : 8),
        Text(
          'Join BradPOS and manage your store',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isLandscape ? 12 : 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isLandscape) {
    return Column(
      children: [
        // Full Name Input
        TextFormField(
          controller: _fullNameController,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          style: TextStyle(fontSize: isLandscape ? 13 : 16),
          decoration: InputDecoration(
            labelText: 'Full Name',
            isDense: true,
            contentPadding: isLandscape
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : null,
            prefixIcon: Icon(Icons.person_outline, size: isLandscape ? 18 : 22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: AppColors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        SizedBox(height: isLandscape ? 8 : 20),

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
            ),
            filled: true,
            fillColor: AppColors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter email';
            }
            if (!value.contains('@')) {
              return 'Enter a valid email';
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
                size: isLandscape ? 18 : 22,
              ),
              onPressed: () => setState(
                () => _obscurePassword = !_obscurePassword,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: AppColors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isLandscape) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return SizedBox(
          height: isLandscape ? 38 : 56,
          child: ElevatedButton(
            onPressed: state is AuthLoading ? null : _onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state is AuthLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: isLandscape ? 13 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
