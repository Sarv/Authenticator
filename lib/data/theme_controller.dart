import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the user's light / dark / system theme choice and persists it.
///
/// A [ChangeNotifier] so `MaterialApp.themeMode` rebuilds the moment the choice
/// changes; the stored value is read once on [load] and written on every change.
/// All storage I/O is isolated here.
class ThemeController extends ChangeNotifier {
  ThemeController({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'sarv_authenticator.theme_mode.v1';
  final FlutterSecureStorage _storage;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Reads the persisted choice, defaulting to [ThemeMode.system].
  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _key);
      _mode = _parse(raw);
      notifyListeners();
    } catch (error) {
      debugPrint('ThemeController.load failed: $error');
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (error) {
      debugPrint('ThemeController.setMode failed: $error');
    }
  }

  static ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
