import 'package:flutter/material.dart';

/// Palet warna utama aplikasi BradPOS (Premium Edition).
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF065F46); // Deep Emerald
  static const Color primaryGradientStart = Color(0xFF065F46);
  static const Color primaryGradientEnd = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFD1FAE5);
  
  // Secondary Colors (Blues)
  static const Color secondary = Color(0xFF2563EB); 
  static const Color secondaryLight = Color(0xFFDBEAFE);
  
  // Neutral / Background
  static const Color background = Color(0xFFF1F5F9); // Slate 100
  static const Color surface = Colors.white;
  static const Color cardShadow = Color(0x0A000000);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  
  // Status Colors
  static const Color success = Color(0xFF059669);
  static const Color positive = Color(0xFF059669); // Alias for compatibility
  static const Color positiveLight = Color(0xFFD1FAE5); // Alias
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  static const Color neutral = Color(0xFF64748B);
  static const Color neutralLight = Color(0xFFF1F5F9);
  
  // Helpers
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
}
