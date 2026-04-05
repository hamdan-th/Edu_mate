import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LibraryTheme {
  LibraryTheme._();

  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.primaryDark;
  static const Color accent = AppColors.secondary;
  static const Color success = AppColors.success;
  static const Color danger = AppColors.error;
  static const Color bg = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color text = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color border = AppColors.border;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient aquaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.blueGlow, primary],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFF59E0B)],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, primary],
  );
}
