import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/core/shared_secure_storage.dart';

enum ThemeModeOption { system, dark, light }

class ThemeNotifier extends StateNotifier<ThemeModeOption> {
  final _storage = sharedSecureStorage;

  ThemeNotifier() : super(ThemeModeOption.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await _storage.read(key: 'theme_mode');
    if (savedTheme != null) {
      state = ThemeModeOption.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeModeOption.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    state = mode;
    await _storage.write(key: 'theme_mode', value: mode.toString());
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeModeOption>((ref) {
  return ThemeNotifier();
});
