import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:smart_merchant_erp/app/config/api_client.dart';
import 'package:smart_merchant_erp/kernel/storage/secure_storage/secure_storage_contract.dart';
import 'package:smart_merchant_erp/modules/authentication/infrastructure/api/auth_remote_api_client.dart';
import 'package:smart_merchant_erp/modules/authentication/infrastructure/dto/auth_dtos.dart';
import 'package:smart_merchant_erp/modules/authentication/presentation/providers/auth_provider.dart';
import 'package:get_it/get_it.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';

class MockAuthRemoteApiClient extends Mock implements AuthRemoteApiClient {}

class MockSecureStorage extends Mock implements SecureStorageContract {}

class MockSessionHolder extends Mock implements SessionHolder {}

void main() {
  late ProviderContainer container;
  late MockAuthRemoteApiClient mockApi;
  late MockSecureStorage mockStorage;
  late MockSessionHolder mockSessionHolder;

  setUpAll(() {
    registerFallbackValue(const LoginRequestDto(email: '', password: ''));
    registerFallbackValue(const BootstrapRequestDto());
    registerFallbackValue(
      const RegisterDeviceRequestDto(businessId: '', deviceUuid: ''),
    );
  });

  setUp(() {
    mockApi = MockAuthRemoteApiClient();
    mockStorage = MockSecureStorage();
    mockSessionHolder = MockSessionHolder();

    GetIt.I.registerSingleton<SessionHolder>(mockSessionHolder);

    // Stub storage writes and deletes
    when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
    when(() => mockStorage.delete(any())).thenAnswer((_) async {});
    when(
      () => mockStorage.read(StorageKeys.deviceUuid),
    ).thenAnswer((_) async => 'test-device-uuid');
    when(
      () => mockStorage.read(StorageKeys.authToken),
    ).thenAnswer((_) async => null);

    GetIt.I.registerSingleton<AuthRemoteApiClient>(mockApi);
    GetIt.I.registerSingleton<SecureStorageContract>(mockStorage);

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    GetIt.I.reset();
  });

  group('AuthNotifier', () {
    test('initial state is initial', () {
      expect(container.read(authNotifierProvider), equals(AuthStatus.initial));
    });

    test('login success updates state to authenticated', () async {
      // Mock Login
      when(() => mockApi.login(any())).thenAnswer(
        (_) async => const LoginResponseDto(
          message: 'Success',
          token: 'test-token',
          user: UserDto(
            id: '1',
            fullName: 'Test User',
            email: 'test@example.com',
            isActive: true,
          ),
        ),
      );

      // Mock Bootstrap
      when(() => mockApi.bootstrap(any())).thenAnswer(
        (_) async => const BootstrapResponseDto(
          user: UserDto(
            id: '1',
            fullName: 'Test User',
            email: 'test@example.com',
            isActive: true,
          ),
          activeBusiness: BusinessDto(id: 'b1', businessName: 'Test Business'),
          availableBusinesses: [],
          allowedBranches: [],
          roles: ['Admin'],
          permissions: [],
        ),
      );

      // Mock Device Registration
      when(() => mockApi.registerDevice(any())).thenAnswer(
        (_) async => const RegisterDeviceResponseDto(
          message: 'Success',
          device: DeviceDto(
            id: 'd1',
            deviceUuid: 'test-device-uuid',
            status: 'active',
          ),
        ),
      );

      final result = await container
          .read(authNotifierProvider.notifier)
          .loginWithLaravel(email: 'test@example.com', password: 'password123');

      expect(
        result.isSuccess,
        isTrue,
        reason: 'Failed with: ${result.errorMessage}',
      );
      expect(
        container.read(authNotifierProvider),
        equals(AuthStatus.authenticated),
      );

      // Verify token was stored
      verify(
        () => mockStorage.write(StorageKeys.authToken, 'test-token'),
      ).called(1);
    });

    test('login handles API validation errors properly', () async {
      when(() => mockApi.login(any())).thenThrow(
        ApiException.validation(
          'Validation failed',
          validationErrors: {
            'email': ['Invalid email'],
          },
        ),
      );

      final result = await container
          .read(authNotifierProvider.notifier)
          .loginWithLaravel(email: 'invalid', password: 'password123');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Invalid email'));
      expect(
        container.read(authNotifierProvider),
        equals(AuthStatus.unauthenticated),
      );
    });

    test('login handles revoked device properly', () async {
      // Mock Login
      when(() => mockApi.login(any())).thenAnswer(
        (_) async => const LoginResponseDto(
          message: 'Success',
          token: 'test-token',
          user: UserDto(
            id: '1',
            fullName: 'Test User',
            email: 'test@example.com',
            isActive: true,
          ),
        ),
      );

      // Mock Bootstrap
      when(() => mockApi.bootstrap(any())).thenAnswer(
        (_) async => const BootstrapResponseDto(
          user: UserDto(
            id: '1',
            fullName: 'Test User',
            email: 'test@example.com',
            isActive: true,
          ),
          activeBusiness: BusinessDto(id: 'b1', businessName: 'Test Business'),
          availableBusinesses: [],
          allowedBranches: [],
          roles: ['Admin'],
          permissions: [],
        ),
      );

      // Mock Device Registration throwing Revoked
      when(
        () => mockApi.registerDevice(any()),
      ).thenThrow(ApiException.deviceRevoked('Device has been revoked'));

      final result = await container
          .read(authNotifierProvider.notifier)
          .loginWithLaravel(email: 'test@example.com', password: 'password123');

      expect(result.isSuccess, isFalse);
      expect(
        result.isDeviceRevokedResult,
        isTrue,
        reason: 'Failed with: ${result.errorMessage}',
      );
      expect(
        container.read(authNotifierProvider),
        equals(AuthStatus.deviceRevoked),
      );
    });
  });
}
