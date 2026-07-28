import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/app/config/api_client.dart';
import 'package:smart_merchant_erp/app/config/app_environment.dart';
import 'package:smart_merchant_erp/app/di/injection.dart';
import 'package:smart_merchant_erp/kernel/storage/secure_storage/secure_storage_contract.dart';
import 'package:smart_merchant_erp/modules/authentication/infrastructure/api/auth_remote_api_client.dart';
import 'package:smart_merchant_erp/modules/authentication/presentation/providers/auth_provider.dart';

// Mock for secure storage to avoid plugin channel errors in pure unit test
class MockSecureStorage implements SecureStorageContract {
  final Map<String, String> _storage = {};
  @override Future<void> write(String key, String value) async => _storage[key] = value;
  @override Future<String?> read(String key) async => _storage[key];
  @override Future<void> delete(String key) async => _storage.remove(key);
  @override Future<void> clearAll() async => _storage.clear();
  @override Future<void> deleteAll() async => _storage.clear();
  @override Future<Map<String, String>> readAll() async => _storage;
}

// Dummy environment for testing
class TestEnvironment implements AppEnvironment {
  @override String get baseUrl => 'http://127.0.0.1:8000/api';
  @override String get environment => 'test';
  @override bool get isProduction => false;
  @override Duration get connectTimeout => const Duration(seconds: 10);
  @override Duration get receiveTimeout => const Duration(seconds: 10);
}

void main() {
  test('Register Integration Test', () async {
    // Basic DI setup for test
    final secureStorage = MockSecureStorage();
    getIt.registerLazySingleton<SecureStorageContract>(() => secureStorage);
    getIt.registerLazySingleton<AppEnvironment>(() => TestEnvironment());
    getIt.registerLazySingleton<ApiClient>(() => ApiClient(environment: getIt<AppEnvironment>(), secureStorage: getIt<SecureStorageContract>()));
    getIt.registerLazySingleton<AuthRemoteApiClient>(() => AuthRemoteApiClient(getIt<ApiClient>()));

    final container = ProviderContainer();
    final notifier = container.read(authNotifierProvider.notifier);

    final result = await notifier.register(
      firstName: 'Test',
      lastName: 'User',
      username: 'testuser_${DateTime.now().millisecondsSinceEpoch}',
      email: 'test_${DateTime.now().millisecondsSinceEpoch}@example.com',
      phone: '12345678',
      password: 'password123',
    );

    print('Result success: ${result.isSuccess}');
    if (!result.isSuccess) {
      print('Error: ${result.errorMessage}');
    }
  });
}
