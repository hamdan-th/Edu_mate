import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary identity (Dark/Gold for dark mode, but acts as secondary luxury accent in light mode)
  static const Color primary = Color(0xFFD2AB52); // Richer, more confident premium gold
  static const Color primaryDark = Color(0xFFB58E3A); // Stronger deep gold
  static const Color secondary = Color(0xFF111111);

  // Light theme identity
  static const Color lightPrimary = Color(0xFF1E4C7A); // Fresher, more visible academic blue
  static const Color lightBackground = Color(0xFFF0F4F8); // Cleaner, brighter blue-tinted base
  static const Color lightSurface = Color(0xFFFFFFFF); // Maximum clarity
  static const Color lightBorder = Color(0xFFCFD6E2); // Slightly stronger border distinction
  static const Color lightGoldAccent = Color(0xFFF8EEDC); // Elegantly visible light gold highlight

  // Backgrounds - Structured Charcoal
  static const Color background = Color(0xFF050608); // Deeper, luxurious pure near-black
  static const Color surface = Color(0xFF15171C); // Clearer charcoal separation
  static const Color darkSurface = Color(0xFF0B0C10);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnLight = Color(0xFF1A1D23);

  // Inputs / borders
  static const Color inputFill = Color(0xFF1B1E24); // Clear contrast against surface
  static const Color inputDarkFill = Color(0xFF0D0F13);
  static const Color border = Color(0xFF2C3038); // Stronger subtle depth

  // Feedback
  static const Color success = Color(0xFF10B981); // Modern green
  static const Color error = Color(0xFFEF4444); // Modern red
  static const Color warning = Color(0xFFF59E0B);

  // Accent glow / highlights (using primary gold smoothly)
  static const Color blueGlow = Color(0xFFD2AB52);
}