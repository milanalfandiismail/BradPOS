import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/core/app_colors.dart';
import 'package:bradpos/presentation/blocs/auth_bloc.dart';

class LoginKaryawanForm extends StatelessWidget {
  final TextEditingController shopIdController;
  final TextEditingController karyawanNameController;
  final TextEditingController karyawanPassController;
  final GlobalKey<FormState> formKey;
  final bool obscurePassword;
  final bool isLandscape;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onLogin;

  const LoginKaryawanForm({
    super.key,
    required this.shopIdController,
    required this.karyawanNameController,
    required this.karyawanPassController,
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
            controller: shopIdController,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: isLandscape ? 13 : 16),
            decoration: InputDecoration(
              labelText: 'Shop ID',
              isDense: true,
              contentPadding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : null,
              hintText: 'Contoh: BAA-2026',
              prefixIcon:
                  Icon(Icons.store_outlined, size: isLandscape ? 18 : 22),
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
            controller: karyawanNameController,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: isLandscape ? 13 : 16),
            decoration: InputDecoration(
              labelText: 'Nama Karyawan',
              isDense: true,
              contentPadding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : null,
              prefixIcon:
                  Icon(Icons.badge_outlined, size: isLandscape ? 18 : 22),
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
            controller: karyawanPassController,
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
                  color: AppColors.secondary,
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
          SizedBox(height: isLandscape ? 12 : 32),

          // Karyawan Login Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SizedBox(
                height: isLandscape ? 38 : 56,
                child: ElevatedButton(
                  onPressed: state is AuthLoading ? null : onLogin,
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
