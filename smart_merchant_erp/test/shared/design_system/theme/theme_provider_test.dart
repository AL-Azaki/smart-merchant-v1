import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_merchant_erp/shared/design_system/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeProvider should default to light mode', () {
    final container = ProviderContainer();
    final theme = container.read(themeNotifierProvider);
    expect(theme, ThemeMode.light);
  });

  test('ThemeProvider should load saved theme from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer();
    final notifier = container.read(themeNotifierProvider.notifier);
    
    await notifier.initialize(prefs);
    
    final theme = container.read(themeNotifierProvider);
    expect(theme, ThemeMode.dark);
  });

  test('ThemeProvider should toggle between light and dark mode', () async {
    final container = ProviderContainer();
    final notifier = container.read(themeNotifierProvider.notifier);
    
    expect(container.read(themeNotifierProvider), ThemeMode.light);
    
    await notifier.toggleTheme();
    expect(container.read(themeNotifierProvider), ThemeMode.dark);
    
    await notifier.toggleTheme();
    expect(container.read(themeNotifierProvider), ThemeMode.light);
  });
}
