import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/app/di/getit_instance.dart';
import 'package:smart_merchant_erp/modules/authentication/presentation/providers/auth_provider.dart';
import 'package:smart_merchant_erp/app/config/app_environment.dart';
import 'package:smart_merchant_erp/app/config/api_client.dart';
import 'package:smart_merchant_erp/modules/authentication/infrastructure/api/auth_remote_api_client.dart';
import 'package:smart_merchant_erp/kernel/storage/secure_storage/secure_storage_contract.dart';
import 'package:smart_merchant_erp/kernel/storage/secure_storage/flutter_secure_storage_impl.dart';

class MockSecureStorage implements SecureStorageContract {
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
  @override
  Future<void> deleteAll() async => _data.clear();
  @override
  Future<Map<String, String>> readAll() async => _data;
}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Manual Real Login Test', () async {
    // Override GetIt for the test
    getIt.registerLazySingleton<AppEnvironment>(() => AppEnvironment.test(baseUrl: 'http://127.0.0.1:8000/api'));
    getIt.registerLazySingleton<SecureStorageContract>(() => MockSecureStorage());
    getIt.registerLazySingleton<ApiClient>(() => ApiClient(environment: getIt<AppEnvironment>(), secureStorage: getIt<SecureStorageContract>()));
    getIt.registerLazySingleton<AuthRemoteApiClient>(() => AuthRemoteApiClient(getIt<ApiClient>()));

    final container = ProviderContainer();
    
    // Listen to state changes
    container.listen(
      authNotifierProvider,
      (previous, next) => print('AuthStatus Transition: $previous -> $next'),
      fireImmediately: true,
    );

    print('Attempting login...');
    final result = await container.read(authNotifierProvider.notifier).loginWithLaravel(
      email: 'admin@smartmerchant.com',
      password: 'password', // Assuming default password is password
    );

    print('Login Success: ${result.isSuccess}');
    if (!result.isSuccess) {
      print('Error: ${result.errorMessage}');
    }

    // Wait a bit to see if state changes
    await Future.delayed(const Duration(seconds: 2));
  });
}
