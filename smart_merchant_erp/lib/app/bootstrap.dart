import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'di/injection.dart';

Future<void> bootstrap(Widget Function() builder) async {
  // 1. Ensure Flutter binding is initialized securely
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Global Error Handling (Security & Stability)
  // We catch all errors globally so the app doesn't crash in production
  // and sensitive error traces aren't exposed to the user.
  FlutterError.onError = (details) {
    if (kReleaseMode) {
      // In production, log securely to a service (e.g., Sentry)
      debugPrint('Secure Log: \${details.exceptionAsString()}');
    } else {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // Handle asynchronous errors outside of Flutter
    debugPrint('Async Error Captured: $error');
    return true; // Prevents crash
  };

  // 3. Initialize Dependency Injection (GetIt)
  configureDependencies();

  // 4. Run the app wrapped in Riverpod's ProviderScope
  runApp(
    ProviderScope(
      child: builder(),
    ),
  );
}
