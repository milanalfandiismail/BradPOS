import 'package:flutter/material.dart';
import 'package:bradpos/core/app_colors.dart';

class GoogleSignInWebButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLandscape;

  const GoogleSignInWebButton({
    super.key,
    required this.onPressed,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        fixedSize: Size.fromHeight(isLandscape ? 38 : 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      icon: Image.network(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
        width: isLandscape ? 16 : 24,
        height: isLandscape ? 16 : 24,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.account_circle_outlined,
          size: isLandscape ? 16 : 24,
          color: AppColors.primary,
        ),
      ),
      label: Text(
        'Continue with Google',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: isLandscape ? 12 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
