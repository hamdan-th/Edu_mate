import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  final SharedPreferences _prefs;

  late ThemeMode _themeMode;
  late Locale _locale;

  AppSettingsProvider(this._prefs) {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  void _loadSettings() {
    // Load ThemeMode
    final themeString = _prefs.getString(_themeModeKey);
    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load Locale
    final localeString = _prefs.getString(_localeKey);
    if (localeString == 'ar') {
      _locale = const Locale('ar');
    } else if (localeString == 'en') {
      _locale = const Locale('en');
    } else {
      // Default to English if not set
      _locale = const Locale('en');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    
    String modeString = 'system';
    if (mode == ThemeMode.light) {
      modeString = 'light';
    } else if (mode == ThemeMode.dark) {
      modeString = 'dark';
    }
    
    await _prefs.setString(_themeModeKey, modeString);
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    await _prefs.setString(_localeKey, newLocale.languageCode);
    notifyListeners();
  }
}
