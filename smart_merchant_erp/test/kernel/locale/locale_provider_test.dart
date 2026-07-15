import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_merchant_erp/kernel/locale/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  test('LocaleProvider should default to Arabic', () {
    final container = ProviderContainer();
    final locale = container.read(localeNotifierProvider);
    expect(locale.languageCode, 'ar');
  });

  test('LocaleProvider should load saved locale from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer();
    final notifier = container.read(localeNotifierProvider.notifier);
    
    await notifier.initialize(prefs);
    
    final locale = container.read(localeNotifierProvider);
    expect(locale.languageCode, 'en');
  });

  test('LocaleProvider should toggle between Arabic and English', () async {
    final container = ProviderContainer();
    final notifier = container.read(localeNotifierProvider.notifier);
    
    expect(container.read(localeNotifierProvider).languageCode, 'ar');
    
    await notifier.toggleLocale();
    expect(container.read(localeNotifierProvider).languageCode, 'en');
    
    await notifier.toggleLocale();
    expect(container.read(localeNotifierProvider).languageCode, 'ar');
  });
}
