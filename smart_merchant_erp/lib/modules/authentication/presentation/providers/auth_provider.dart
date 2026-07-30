import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/config/api_client.dart';
import '../../../../app/config/app_environment.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/secure_storage/secure_storage_contract.dart';
import '../../infrastructure/api/auth_remote_api_client.dart';
import '../../infrastructure/dto/auth_dtos.dart';
import 'session_provider.dart';
import '../../../../kernel/storage/app_database.dart';
import 'package:drift/drift.dart' as drift;

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
    // Wait for a brief moment to ensure DI is fully ready and to
    await Future.delayed(const Duration(milliseconds: 500));

    if (AppEnvironment.isQaBypassEnabled) {
      _bootstrapQaSession();
      return;
    }

    final restored = await tryRestoreSession();
    if (!restored) {
      state = AuthStatus.unauthenticated;
    }
  }

  void _bootstrapQaSession() {
    debugPrint('QA ACCESS MODE: BYPASSING AUTHENTICATION');
    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
    sessionNotifier.setSession(
      businessId: 'qa-business-id',
      branchId: 'qa-branch-id',
      userId: 'qa-user-id',
    );
    state = AuthStatus.authenticated;
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

      return await _completeAuthenticatedSession(loginResponse.token);
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

      await _hydrateLocalSessionData(bootstrapResponse);

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

      // Update setup/subscription state
      if (bootstrapResponse.activeBusiness.businessType == null) {
        state = AuthStatus.setupRequired;
      } else if (bootstrapResponse.subscription != null) {
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
    if (AppEnvironment.isQaBypassEnabled) {
      // In QA mode, logout just re-bootstraps the QA session to prevent loops
      _bootstrapQaSession();
    } else {
      state = AuthStatus.unauthenticated;
    }
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
      debugPrint('REGISTER_HTTP_START');
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
      debugPrint('REGISTER_HTTP_STATUS=201');
      debugPrint('REGISTER_TOKEN_RECEIVED=true');

      return await _completeAuthenticatedSession(registerResponse.token);
    } on ApiException catch (e) {
      debugPrint('REGISTER_API_EXCEPTION: ${e.message}');
      state = AuthStatus.unauthenticated;
      if (e.type == ApiExceptionType.validation) {
        return LoginResult.failure(
          e.validationErrors?.values.first.first ?? e.message,
        );
      }
      return LoginResult.failure(e.message);
    } catch (e) {
      debugPrint('REGISTER_UNKNOWN_EXCEPTION: $e');
      state = AuthStatus.unauthenticated;
      return LoginResult.failure(e.toString());
    }
  }

  Future<LoginResult> _completeAuthenticatedSession(String token) async {
    try {
      // 2. Securely persist token
      await _secureStorage.write(StorageKeys.authToken, token);

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

      await _hydrateLocalSessionData(bootstrapResponse);

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
      }

      // 7. Determine setup/subscription state
      if (bootstrapResponse.activeBusiness.businessType == null) {
        state = AuthStatus.setupRequired;
      } else if (bootstrapResponse.subscription != null) {
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
    } catch (e) {
      state = AuthStatus.unauthenticated;
      return LoginResult.failure(e.toString());
    }
  }

  Future<void> completeSetup(Map<String, dynamic> setupData) async {
    try {
      state = AuthStatus.authenticating;
      await _authApi.setupBusiness(setupData);

      // Refresh bootstrap to get updated business context
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

      await _hydrateLocalSessionData(bootstrapResponse);

      // Update state
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
    } catch (e) {
      debugPrint('SETUP_EXCEPTION: $e');
      state = AuthStatus.setupRequired; // Revert if failed
    }
  }

  Future<void> requestSubscription() async {}

  String _getDeviceName() {
    try {
      return '${Platform.operatingSystem}-${Platform.localHostname}';
    } catch (_) {
      return 'flutter-device';
    }
  }

  Future<void> _hydrateLocalSessionData(BootstrapResponseDto bootstrap) async {
    try {
      final db = getIt<AppDatabase>();
      await db.transaction(() async {
        // Upsert User
        await db
            .into(db.usersTable)
            .insertOnConflictUpdate(
              UsersTableCompanion.insert(
                id: drift.Value(bootstrap.user.id),
                email: bootstrap.user.email,
                passwordHash: '',
                firstName: bootstrap.user.fullName.split(' ').first,
                lastName: bootstrap.user.fullName.split(' ').length > 1
                    ? bootstrap.user.fullName.split(' ').sublist(1).join(' ')
                    : '',
                isActive: drift.Value(bootstrap.user.isActive),
              ),
            );

        // Upsert Default Currency 'YER' (Required for Sales Invoices FK)
        await db
            .into(db.currencies)
            .insertOnConflictUpdate(
              CurrenciesCompanion.insert(
                id: 'YER',
                currencyCode: 'YER',
                currencyNameAr: 'ريال يمني',
                currencyNameEn: 'Yemeni Rial',
                currencySymbol: '﷼',
                isBaseCurrency: const drift.Value(true),
                isActive: const drift.Value(true),
              ),
            );

        // Create a dummy account if needed for businesses
        final dummyAccountId = 'system-account-${bootstrap.user.id}';
        await db
            .into(db.accountsTable)
            .insertOnConflictUpdate(
              AccountsTableCompanion.insert(
                id: drift.Value(dummyAccountId),
                ownerId: bootstrap.user.id,
                businessName: bootstrap.activeBusiness.businessName,
                businessType: bootstrap.activeBusiness.businessType ?? 'Retail',
                defaultCurrency: 'YER',
              ),
            );

        // Upsert Business
        await db
            .into(db.businesses)
            .insertOnConflictUpdate(
              BusinessesCompanion.insert(
                id: bootstrap.activeBusiness.id,
                accountId: dummyAccountId,
                businessName: bootstrap.activeBusiness.businessName,
                businessType: drift.Value(
                  bootstrap.activeBusiness.businessType,
                ),
                status: drift.Value(
                  bootstrap.activeBusiness.status ?? 'Active',
                ),
              ),
            );

        // Upsert Branch
        if (bootstrap.activeBranch != null) {
          await db
              .into(db.branches)
              .insertOnConflictUpdate(
                BranchesCompanion.insert(
                  id: bootstrap.activeBranch!.id,
                  businessId: bootstrap.activeBusiness.id,
                  branchName: bootstrap.activeBranch!.branchName,
                  branchCode: bootstrap.activeBranch!.branchCode ?? 'MAIN',
                  isActive: drift.Value(bootstrap.activeBranch!.isActive),
                ),
              );
        }
      });
    } catch (e) {
      debugPrint('HYDRATION ERROR: $e');
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
