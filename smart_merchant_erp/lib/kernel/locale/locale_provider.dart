import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  static const _localeKey = 'app_locale';

  @override
  Locale build() {
    // Default to Arabic
    return const Locale('ar');
  }

  Future<void> initialize(SharedPreferences prefs) async {
    final savedCode = prefs.getString(_localeKey);
    if (savedCode != null) {
      state = Locale(savedCode);
    }
  }

  Future<void> toggleLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final newLocale = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    await prefs.setString(_localeKey, newLocale.languageCode);
    state = newLocale;
  }
}
