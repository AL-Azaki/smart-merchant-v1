/// Application environment configuration for API connectivity.
/// Injected into the API client; supports dev/test/production switching.
class AppEnvironment {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final String envName;

  const AppEnvironment({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    required this.envName,
  });

  static const String customBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: '');

  /// Development / local server.
  factory AppEnvironment.development() => AppEnvironment(
    baseUrl: customBaseUrl.isNotEmpty ? customBaseUrl : 'http://127.0.0.1:8000/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    envName: 'development',
  );

  /// QA server/mode.
  factory AppEnvironment.qa() => AppEnvironment(
    baseUrl: customBaseUrl.isNotEmpty ? customBaseUrl : 'http://127.0.0.1:8000/api',
    envName: 'qa',
  );

  /// Production server.
  factory AppEnvironment.production() =>
      AppEnvironment(
        baseUrl: customBaseUrl.isNotEmpty ? customBaseUrl : 'http://127.0.0.1:8000/api',
        envName: 'production',
      );

  /// Testing — base URL is overridden per test.
  factory AppEnvironment.test({String baseUrl = 'http://localhost:8080/api'}) =>
      AppEnvironment(baseUrl: baseUrl, envName: 'test');

  static const String currentEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const bool _enableQaAuthBypassFlag = bool.fromEnvironment('ENABLE_QA_AUTH_BYPASS', defaultValue: false);

  /// Safe check for QA Bypass. Fails closed in production.
  static bool get isQaBypassEnabled {
    if (currentEnv == 'production') return false; // HARD GUARD
    if (currentEnv != 'qa' && currentEnv != 'development') return false;
    return _enableQaAuthBypassFlag;
  }

  static AppEnvironment get current {
    if (customBaseUrl.isNotEmpty) {
      return AppEnvironment(
        baseUrl: customBaseUrl,
        envName: currentEnv.isNotEmpty ? currentEnv : 'custom',
      );
    }
    switch (currentEnv) {
      case 'development':
        return AppEnvironment.development();
      case 'qa':
        return AppEnvironment.qa();
      case 'test':
        return AppEnvironment.test();
      case 'production':
      default:
        return AppEnvironment.production();
    }
  }
}
