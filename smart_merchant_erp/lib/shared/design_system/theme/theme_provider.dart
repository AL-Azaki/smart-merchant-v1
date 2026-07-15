import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  static const _themeModeKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    // Default to light or system
    return ThemeMode.light;
  }

  Future<void> initialize(SharedPreferences prefs) async {
    final savedMode = prefs.getString(_themeModeKey);
    if (savedMode == 'dark') {
      state = ThemeMode.dark;
    } else if (savedMode == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await prefs.setString(_themeModeKey, newMode.name);
    state = newMode;
  }
}
