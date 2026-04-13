import 'package:flutter/material.dart';

class LibraryTheme {
  // ========================
  // SAFE THEME ACCESS
  // ========================

  static Color bg(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color text(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Colors.white.withOpacity(0.92);
    }
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  static Color muted(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Colors.white.withOpacity(0.55);
    }
    return Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
  }

  static Color border(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Colors.white.withOpacity(0.08);
    }
    return Theme.of(context).dividerColor;
  }

  // ========================
  // BRAND COLORS (Legacy fallbacks)
  // ========================

  static const Color successColor = Color(0xFF43A047);

  // ========================
  // SAFE WRAPPERS
  // ========================

  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  
  // Restored compatibility wrappers
  static Color secondary(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color error(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color danger(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color success(BuildContext context) => successColor;
}