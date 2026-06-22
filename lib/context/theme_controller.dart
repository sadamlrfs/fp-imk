import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app-wide display preferences (theme mode + font scale) and
/// notifies [MaterialApp] when they change so the UI actually re-themes.
///
/// The label strings ('Terang' / 'Gelap' / 'Sistem') match what the
/// appearance page persists under `app_theme`.
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  double _fontSize = 14;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  double get textScale => _fontSize / 14.0;

  static ThemeMode _modeFromLabel(String label) {
    switch (label) {
      case 'Gelap':
        return ThemeMode.dark;
      case 'Sistem':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _themeMode = _modeFromLabel(p.getString('app_theme') ?? 'Terang');
    _fontSize = p.getDouble('app_font_size') ?? 14;
    notifyListeners();
  }

  Future<void> setThemeLabel(String label) async {
    _themeMode = _modeFromLabel(label);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('app_theme', label);
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble('app_font_size', size);
  }
}
