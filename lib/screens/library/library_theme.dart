import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LibraryTheme {
  LibraryTheme._();

  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color secondary(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color accent(BuildContext context) => const Color(0xFFF59E0B);
  static Color success(BuildContext context) => Colors.green;
  static Color danger(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color bg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color text(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  static Color muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  static Color border(BuildContext context) => Theme.of(context).dividerColor.withOpacity(0.08);

  static LinearGradient primaryGradient(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary(context), secondary(context)],
  );

  static LinearGradient aquaGradient(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.blueGlow, primary(context)],
  );

  static LinearGradient amberGradient(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent(context), const Color(0xFFF59E0B)],
  );

  static LinearGradient mintGradient(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success(context), primary(context)],
  );
}

