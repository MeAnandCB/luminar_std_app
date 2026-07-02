import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _variantKey = 'app_theme_variant';

  ThemeMode _themeMode = ThemeMode.light;
  AppThemeVariant _variant = AppThemeVariant.luminar;

  ThemeProvider() {
    _loadPrefs();
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        _onSystemBrightnessChanged;
  }

  ThemeMode get themeMode => _themeMode;
  AppThemeVariant get variant => _variant;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void _onSystemBrightnessChanged() {
    if (_themeMode == ThemeMode.system) {
      _syncAppColors();
      notifyListeners();
    }
  }

  void _syncAppColors() {
    AppColors.updateTheme(isDarkMode);
    AppColors.updateVariant(_variant);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final savedMode = prefs.getString(_themeKey);
    if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedMode == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    // Load variant
    final savedVariant = prefs.getString(_variantKey);
    _variant = savedVariant == 'ocean' ? AppThemeVariant.ocean : AppThemeVariant.luminar;

    _syncAppColors();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _syncAppColors();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final modeString = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.system
            ? 'system'
            : 'light';
    await prefs.setString(_themeKey, modeString);
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    if (_variant == variant) return;
    _variant = variant;
    _syncAppColors();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _variantKey, variant == AppThemeVariant.ocean ? 'ocean' : 'luminar');
  }

  void toggleTheme() {
    setThemeMode(
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
