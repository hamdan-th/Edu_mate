import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edu_mate/l10n/app_localizations.dart';

import '../../core/providers/app_settings_provider.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  static void show(BuildContext context) {
    final settingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: settingsProvider,
        child: const SettingsBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsProvider = context.watch<AppSettingsProvider>();
    final currentLocale = settingsProvider.locale ?? Localizations.localeOf(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: theme.dividerTheme.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.settings,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          // Language Setting
          Text(
            l10n.language,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OptionButton(
                  title: 'English',
                  isSelected: currentLocale.languageCode == 'en',
                  onTap: () => settingsProvider.setLocale(const Locale('en')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionButton(
                  title: 'العربية',
                  isSelected: currentLocale.languageCode == 'ar',
                  onTap: () => settingsProvider.setLocale(const Locale('ar')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Theme Setting
          Text(
            l10n.theme,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OptionButton(
                  title: l10n.themeSystem,
                  isSelected: settingsProvider.themeMode == ThemeMode.system,
                  onTap: () => settingsProvider.setThemeMode(ThemeMode.system),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OptionButton(
                  title: l10n.themeLight,
                  isSelected: settingsProvider.themeMode == ThemeMode.light,
                  onTap: () => settingsProvider.setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OptionButton(
                  title: l10n.themeDark,
                  isSelected: settingsProvider.themeMode == ThemeMode.dark,
                  onTap: () => settingsProvider.setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipTheme = theme.chipTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? chipTheme.selectedColor : chipTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : (chipTheme.shape as RoundedRectangleBorder).side.color,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: isSelected ? chipTheme.secondaryLabelStyle : chipTheme.labelStyle,
        ),
      ),
    );
  }
}
