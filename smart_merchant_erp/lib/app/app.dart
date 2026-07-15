import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import 'routes/app_router.dart';
import '../shared/design_system/theme/app_theme.dart';
import '../kernel/locale/locale_provider.dart';
import '../shared/design_system/theme/theme_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router, locale, and theme providers
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeNotifierProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      // We will remove hardcoded title since we can't easily access l10n before context is built,
      // but we use onGenerateTitle instead if needed. For now, a generic English/Arabic string.
      title: 'Smart Merchant - التاجر الذكي',
      debugShowCheckedModeBanner: false,
      
      // Localization Support
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      
      // Routing integration
      routerConfig: router,
      
      // Centralized Premium Design System
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
    );
  }
}
