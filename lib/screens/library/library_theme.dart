import 'package:flutter/material.dart';

class LibraryTheme {
  // ========================
  // SAFE THEME ACCESS
  // ========================

  static Color bg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color text(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

  static Color muted(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;

  static Color border(BuildContext context) =>
      Theme.of(context).dividerColor;

  // ========================
  // BRAND COLORS (ثابتة)
  // ========================

  static const Color primaryColor = Color(0xFFD4AF37);
  static const Color secondaryColor = Color(0xFFFFC107);
  static const Color accentColor = Color(0xFFB8962E);

  static const Color dangerColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);

  // ========================
  // SAFE WRAPPERS (مهم جدا)
  // ========================

  static Color primary(BuildContext context) => primaryColor;
  static Color secondary(BuildContext context) => secondaryColor;
  static Color accent(BuildContext context) => accentColor;

  static Color danger(BuildContext context) => dangerColor;
  static Color success(BuildContext context) => successColor;
}