/// Application environment configuration for API connectivity.
/// Injected into the API client; supports dev/test/production switching.
class AppEnvironment {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const AppEnvironment({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  /// Development / local server.
  factory AppEnvironment.development() => const AppEnvironment(
    baseUrl: 'http://10.0.2.2:8000/api', // Android emulator → host
  );

  /// Production server.
  factory AppEnvironment.production() =>
      const AppEnvironment(baseUrl: 'https://api.smartmerchant.app/api');

  /// Testing — base URL is overridden per test.
  factory AppEnvironment.test({String baseUrl = 'http://localhost:8080/api'}) =>
      AppEnvironment(baseUrl: baseUrl);
}
