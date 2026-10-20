import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({Future<bool> Function(String)? persistMode})
    : _persistMode = persistMode;
  final Future<bool> Function(String)? _persistMode;
  static final instance = ThemeController();
  static const storageKey = 'appearance_theme_mode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  bool _saving = false;
  bool get saving => _saving;

  Future<void> load() async {
    try {
      final value = (await SharedPreferences.getInstance()).getString(
        storageKey,
      );
      _mode =
          ThemeMode.values.where((mode) => mode.name == value).firstOrNull ??
          ThemeMode.system;
    } catch (_) {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    if (_saving || value == _mode) return;
    _saving = true;
    notifyListeners();
    try {
      final saved = _persistMode != null
          ? await _persistMode(value.name)
          : await (await SharedPreferences.getInstance()).setString(
              storageKey,
              value.name,
            );
      if (!saved) throw StateError('Impossible de conserver cette préférence');
      _mode = value;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
