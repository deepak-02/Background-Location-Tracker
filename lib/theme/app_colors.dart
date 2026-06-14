import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background
  static const scaffoldBg = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const cardBorder = Color(0xFF334155);

  // Primary gradient
  static const primaryIndigo = Color(0xFF6366F1);
  static const primaryViolet = Color(0xFF8B5CF6);

  // Accents
  static const accentCyan = Color(0xFF06B6D4);
  static const accentEmerald = Color(0xFF10B981);

  // Status
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFF43F5E);

  // Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [primaryIndigo, primaryViolet],
  );

  static const dangerGradient = LinearGradient(
    colors: [Color(0xFFDC2626), error],
  );
}
