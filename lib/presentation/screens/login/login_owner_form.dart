import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/core/utils/app_navigator.dart';
import 'register_screen.dart';

class LoginOwnerForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final bool obscurePassword;
  final bool isLandscape;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onLogin;

  const LoginOwnerForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.obscurePassword,
    required this.isLandscape,
    required this.onToggleObscurePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        key: const ValueKey('owner_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Input
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: isLandscape ? 13 : 16),
            decoration: InputDecoration(
              labelText: 'Email Address',
              isDense: true,
              contentPadding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : null,
              prefixIcon:
                  Icon(Icons.email_outlined, size: isLandscape ? 18 : 22),
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
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            style: TextStyle(fontSize: isLandscape ? 13 : 16),
            decoration: InputDecoration(
              labelText: 'Password',
              isDense: true,
              contentPadding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : null,
              prefixIcon:
                  Icon(Icons.lock_outline, size: isLandscape ? 18 : 22),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: isLandscape ? 18 : 22,
                ),
                onPressed: onToggleObscurePassword,
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
            onFieldSubmitted: (_) => onLogin(),
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
                  onPressed: state is AuthLoading ? null : onLogin,
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
}
