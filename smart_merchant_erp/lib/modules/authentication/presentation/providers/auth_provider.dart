import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/config/api_client.dart';
import '../../../../app/di/injection.dart';
import '../../../../kernel/storage/secure_storage/secure_storage_contract.dart';
import '../../infrastructure/api/auth_remote_api_client.dart';
import '../../infrastructure/dto/auth_dtos.dart';
import 'session_provider.dart';

part 'auth_provider.g.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  setupRequired,
  trialActive,
  subscriptionExpired,
  subscriptionPending,
  authenticated,
  deviceRevoked,
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  AuthRemoteApiClient get _authApi => getIt<AuthRemoteApiClient>();
  SecureStorageContract get _secureStorage => getIt<SecureStorageContract>();

  @override
  AuthStatus build() {
    _initialize();
    return AuthStatus.initial;
  }

  Future<void> _initialize() async {
    // Wait for a brief moment to ensure DI is fully ready and to show splash screen naturally
    await Future.delayed(const Duration(milliseconds: 500));
    final restored = await tryRestoreSession();
    if (!restored) {
      state = AuthStatus.unauthenticated;
    }
  }

  /// Full login flow: authenticate → store token → bootstrap → register device.
  Future<LoginResult> loginWithLaravel({
    required String email,
    required String password,
  }) async {
    state = AuthStatus.authenticating;

    try {
      // 1. Authenticate with Laravel Sanctum
      final loginResponse = await _authApi.login(
        LoginRequestDto(
          email: email,
          password: password,
          deviceName: _getDeviceName(),
        ),
      );

      // 2. Securely persist token
      await _secureStorage.write(StorageKeys.authToken, loginResponse.token);

      // 3. Ensure stable device UUID
      String? deviceUuid = await _secureStorage.read(StorageKeys.deviceUuid);
      if (deviceUuid == null || deviceUuid.isEmpty) {
        deviceUuid = const Uuid().v4();
        await _secureStorage.write(StorageKeys.deviceUuid, deviceUuid);
      }

      // 4. Bootstrap session
      final bootstrapResponse = await _authApi.bootstrap(
        BootstrapRequestDto(deviceUuid: deviceUuid),
      );

      // 5. Update SessionHolder with real IDs
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      sessionNotifier.setSession(
        businessId: bootstrapResponse.activeBusiness.id,
        branchId: bootstrapResponse.activeBranch?.id,
        userId: bootstrapResponse.user.id,
      );

      // Cache for offline support
      await _secureStorage.write(
        StorageKeys.lastSessionBusinessId,
        bootstrapResponse.activeBusiness.id,
      );
      await _secureStorage.write(
        StorageKeys.lastSessionUserId,
        bootstrapResponse.user.id,
      );
      if (bootstrapResponse.activeBranch?.id != null) {
        await _secureStorage.write(
          StorageKeys.lastSessionBranchId,
          bootstrapResponse.activeBranch!.id,
        );
      } else {
        await _secureStorage.delete(StorageKeys.lastSessionBranchId);
      }

      // 6. Register device
      try {
        await _authApi.registerDevice(
          RegisterDeviceRequestDto(
            businessId: bootstrapResponse.activeBusiness.id,
            deviceUuid: deviceUuid,
            deviceName: _getDeviceName(),
            platform: Platform.operatingSystem,
            appVersion: '1.0.0',
          ),
        );
      } on ApiException catch (e) {
        if (e.type == ApiExceptionType.deviceRevoked) {
          state = AuthStatus.deviceRevoked;
          return LoginResult.deviceRevoked(e.message);
        }
        // Non-fatal: device registration failure doesn't block login
      }

      // 7. Determine subscription state
      if (bootstrapResponse.subscription != null) {
        final subStatus = bootstrapResponse.subscription!.status;
        if (subStatus == 'Active') {
          state = AuthStatus.authenticated;
        } else if (subStatus == 'Expired') {
          state = AuthStatus.subscriptionExpired;
        } else {
          state = AuthStatus.subscriptionPending;
        }
      } else {
        state = AuthStatus.authenticated;
      }

      return LoginResult.success(bootstrapResponse);
    } on ApiException catch (e) {
      state = AuthStatus.unauthenticated;
      if (e.type == ApiExceptionType.validation) {
        return LoginResult.failure(
          e.validationErrors?['email']?.first ?? e.message,
        );
      }
      return LoginResult.failure(e.message);
    } catch (e) {
      state = AuthStatus.unauthenticated;
      return LoginResult.failure(e.toString());
    }
  }

  /// Attempt to restore session from stored token on app startup.
  Future<bool> tryRestoreSession() async {
    final token = await _secureStorage.read(StorageKeys.authToken);
    if (token == null || token.isEmpty) return false;

    try {
      final deviceUuid = await _secureStorage.read(StorageKeys.deviceUuid);
      final bootstrapResponse = await _authApi.bootstrap(
        BootstrapRequestDto(deviceUuid: deviceUuid),
      );

      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      sessionNotifier.setSession(
        businessId: bootstrapResponse.activeBusiness.id,
        branchId: bootstrapResponse.activeBranch?.id,
        userId: bootstrapResponse.user.id,
      );

      // Cache for offline support
      await _secureStorage.write(
        StorageKeys.lastSessionBusinessId,
        bootstrapResponse.activeBusiness.id,
      );
      await _secureStorage.write(
        StorageKeys.lastSessionUserId,
        bootstrapResponse.user.id,
      );
      if (bootstrapResponse.activeBranch?.id != null) {
        await _secureStorage.write(
          StorageKeys.lastSessionBranchId,
          bootstrapResponse.activeBranch!.id,
        );
      } else {
        await _secureStorage.delete(StorageKeys.lastSessionBranchId);
      }

      // Update subscription state
      if (bootstrapResponse.subscription != null) {
        final subStatus = bootstrapResponse.subscription!.status;
        if (subStatus == 'Active') {
          state = AuthStatus.authenticated;
        } else if (subStatus == 'Expired') {
          state = AuthStatus.subscriptionExpired;
        } else {
          state = AuthStatus.subscriptionPending;
        }
      } else {
        state = AuthStatus.authenticated;
      }

      return true;
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.unauthorized) {
        await _secureStorage.delete(StorageKeys.authToken);
      } else if (e.type == ApiExceptionType.deviceRevoked) {
        state = AuthStatus.deviceRevoked;
        return false;
      }
      if (e.type == ApiExceptionType.noNetwork ||
          e.type == ApiExceptionType.timeout) {
        // Offline mode: restore from secure storage cache
        final cachedBusinessId = await _secureStorage.read(
          StorageKeys.lastSessionBusinessId,
        );
        final cachedUserId = await _secureStorage.read(
          StorageKeys.lastSessionUserId,
        );

        if (cachedBusinessId != null && cachedUserId != null) {
          final cachedBranchId = await _secureStorage.read(
            StorageKeys.lastSessionBranchId,
          );
          final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
          sessionNotifier.setSession(
            businessId: cachedBusinessId,
            branchId: cachedBranchId,
            userId: cachedUserId,
          );
          state = AuthStatus.authenticated;
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Logout: clear token, clear session, preserve SQLite operational data.
  Future<void> logout() async {
    // Try server-side logout (non-blocking)
    try {
      await _authApi.logout();
    } catch (_) {}

    // Clear secure credentials
    await _secureStorage.delete(StorageKeys.authToken);
    await _secureStorage.delete(StorageKeys.lastSessionBusinessId);
    await _secureStorage.delete(StorageKeys.lastSessionBranchId);
    await _secureStorage.delete(StorageKeys.lastSessionUserId);

    // Clear runtime session
    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
    sessionNotifier.clearSession();

    // Do NOT delete SQLite operational data
    state = AuthStatus.unauthenticated;
  }

  Future<LoginResult> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = AuthStatus.authenticating;

    try {
      // 1. Authenticate with Laravel Sanctum via Register
      final registerResponse = await _authApi.register(
        RegisterRequestDto(
          firstName: firstName,
          lastName: lastName,
          username: username,
          email: email,
          phone: phone,
          password: password,
          deviceName: _getDeviceName(),
        ),
      );

      // 2. Securely persist token
      await _secureStorage.write(StorageKeys.authToken, registerResponse.token);

      // 3. Ensure stable device UUID
      String? deviceUuid = await _secureStorage.read(StorageKeys.deviceUuid);
      if (deviceUuid == null || deviceUuid.isEmpty) {
        deviceUuid = const Uuid().v4();
        await _secureStorage.write(StorageKeys.deviceUuid, deviceUuid);
      }

      // 4. Bootstrap session
      final bootstrapResponse = await _authApi.bootstrap(
        BootstrapRequestDto(deviceUuid: deviceUuid),
      );

      // 5. Update SessionHolder with real IDs
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      sessionNotifier.setSession(
        businessId: bootstrapResponse.activeBusiness.id,
        branchId: bootstrapResponse.activeBranch?.id,
        userId: bootstrapResponse.user.id,
      );

      // Cache for offline support
      await _secureStorage.write(StorageKeys.lastSessionBusinessId, bootstrapResponse.activeBusiness.id);
      await _secureStorage.write(StorageKeys.lastSessionUserId, bootstrapResponse.user.id);
      if (bootstrapResponse.activeBranch?.id != null) {
        await _secureStorage.write(StorageKeys.lastSessionBranchId, bootstrapResponse.activeBranch!.id);
      } else {
        await _secureStorage.delete(StorageKeys.lastSessionBranchId);
      }

      // 6. Register device
      try {
        await _authApi.registerDevice(
          RegisterDeviceRequestDto(
            businessId: bootstrapResponse.activeBusiness.id,
            deviceUuid: deviceUuid,
            deviceName: _getDeviceName(),
            platform: Platform.operatingSystem,
            appVersion: '1.0.0',
          ),
        );
      } on ApiException catch (e) {
        if (e.type == ApiExceptionType.deviceRevoked) {
          state = AuthStatus.deviceRevoked;
          return LoginResult.deviceRevoked(e.message);
        }
      }

      // 7. Determine subscription state
      if (bootstrapResponse.subscription != null) {
        final subStatus = bootstrapResponse.subscription!.status;
        if (subStatus == 'Active') {
          state = AuthStatus.authenticated;
        } else if (subStatus == 'Expired') {
          state = AuthStatus.subscriptionExpired;
        } else {
          state = AuthStatus.subscriptionPending;
        }
      } else {
        state = AuthStatus.authenticated;
      }

      return LoginResult.success(bootstrapResponse);
    } on ApiException catch (e) {
      state = AuthStatus.unauthenticated;
      if (e.type == ApiExceptionType.validation) {
        return LoginResult.failure(e.validationErrors?.values.first.first ?? e.message);
      }
      return LoginResult.failure(e.message);
    } catch (e) {
      state = AuthStatus.unauthenticated;
      return LoginResult.failure(e.toString());
    }
  }

  Future<void> completeSetup() async {}

  Future<void> requestSubscription() async {}

  String _getDeviceName() {
    try {
      return '${Platform.operatingSystem}-${Platform.localHostname}';
    } catch (_) {
      return 'flutter-device';
    }
  }
}

/// Result of a login attempt.
class LoginResult {
  final bool isSuccess;
  final bool isDeviceRevokedResult;
  final String? errorMessage;
  final BootstrapResponseDto? bootstrap;

  const LoginResult.success(this.bootstrap)
    : isSuccess = true,
      isDeviceRevokedResult = false,
      errorMessage = null;

  const LoginResult.failure(this.errorMessage)
    : isSuccess = false,
      isDeviceRevokedResult = false,
      bootstrap = null;

  const LoginResult.deviceRevoked(this.errorMessage)
    : isSuccess = false,
      isDeviceRevokedResult = true,
      bootstrap = null;
}
