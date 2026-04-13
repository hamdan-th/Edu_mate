import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Displays a bottom-sheet prompt asking the guest to sign in or create an account.
///
/// Call via [GuestActionDialog.show(context)].
/// Does NOT contain any write logic — purely UI.
class GuestActionDialog {
  GuestActionDialog._();

  static Future<void> show(BuildContext context, {String? title, String? subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151A22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                title ?? 'هذه الميزة للأعضاء فقط',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                subtitle ?? 'سجّل دخولك أو أنشئ حسابًا مجانيًا\nللتفاعل مع المحتوى.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark
                      ? AppColors.textSecondary
                      : Colors.black54,
                ),
              ),
              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Signup button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/signup',
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'إنشاء حساب مجاني',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
