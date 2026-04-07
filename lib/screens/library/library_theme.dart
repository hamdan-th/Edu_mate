import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LibraryTheme {
  LibraryTheme._();

  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color secondary(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color success(BuildContext context) => Colors.green;
  static Color danger(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color bg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color text(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  static Color muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  static Color border(BuildContext context) => Theme.of(context).dividerColor.withOpacity(0.08);

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDark],
  );

  static LinearGradient aquaGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.blueGlow, AppColors.primary],
  );

  static LinearGradient amberGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, Color(0xFFF59E0B)],
  );

  static LinearGradient mintGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.success, AppColors.primary],
  );
}

class LibrarySpacing {
  static EdgeInsets card = const EdgeInsets.symmetric(horizontal: 14, vertical: 14);
  static EdgeInsets gridCard = const EdgeInsets.all(12);
  static EdgeInsets badge = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
}

class LibraryRadius {
  static const double card = 20.0;
  static const double badge = 999.0;
}

class LibraryShadows {
  static List<BoxShadow> soft(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

class LibraryTextStyles {
  static TextStyle badge(BuildContext context, Color color) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        );
  }

  static TextStyle title(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.3,
        );
  }

  static TextStyle subtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
  }
}

