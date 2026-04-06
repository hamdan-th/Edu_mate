import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary identity
  static const Color primary = Color(0xFFD4AF37);
  static const Color primaryDark = Color(0xFFB68A1E);
  static const Color secondary = Color(0xFF111111);

  // Backgrounds - Structured Charcoal / Academic Light
  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF1A1D23);
  static const Color darkSurface = Color(0xFF0B0D11);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnLight = Color(0xFF111111);

  // Inputs / borders
  static const Color inputFill = Color(0xFF1A1D23);
  static const Color inputDarkFill = Color(0xFF111318);
  static const Color border = Color(0xFF2A2E35);

  // Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  // Accent glow / highlights (using primary gold smoothly)
  static const Color blueGlow = Color(0xFFD4AF37);
}