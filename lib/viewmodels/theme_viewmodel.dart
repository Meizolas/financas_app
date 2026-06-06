import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  static const _key = 'dark_theme';
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeViewModel() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, _isDark);
    notifyListeners();
  }
}
