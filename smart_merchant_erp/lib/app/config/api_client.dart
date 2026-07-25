import 'dart:io';
import 'package:dio/dio.dart';
import '../../kernel/storage/secure_storage/secure_storage_contract.dart';
import 'app_environment.dart';

/// Keys used in secure storage for auth / device persistence.
class StorageKeys {
  static const authToken = 'auth_token';
  static const deviceUuid = 'device_uuid';
  static const lastPullCursor = 'last_pull_cursor';
  static const lastSyncTimestamp = 'last_sync_timestamp';
  static const lastSessionBusinessId = 'last_session_business_id';
  static const lastSessionBranchId = 'last_session_branch_id';
  static const lastSessionUserId = 'last_session_user_id';
}

/// Centralized HTTP client for all Laravel API communication.
///
/// Responsibilities:
/// - Base URL configuration via [AppEnvironment]
/// - Bearer token injection from [SecureStorageContract]
/// - X-Device-ID header injection
/// - Structured exception mapping for 401/403/409/422/429/5xx
/// - Network-unavailable errors
///
/// All repositories and sync coordinators use this single client.
class ApiClient {
  final Dio _dio;
  final SecureStorageContract _secureStorage;

  ApiClient({
    required AppEnvironment environment,
    required SecureStorageContract secureStorage,
    Dio? dio,
  }) : _secureStorage = secureStorage,
       _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = environment.baseUrl
      ..connectTimeout = environment.connectTimeout
      ..receiveTimeout = environment.receiveTimeout
      ..headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

    _dio.interceptors.add(_AuthInterceptor(_secureStorage));
  }

  /// Exposed for tests that need to inject a mock adapter.
  Dio get dio => _dio;

  // ── HTTP verbs ────────────────────────────────────────────

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    return _execute(() => _dio.get(path, queryParameters: queryParams));
  }

  Future<ApiResponse> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParams,
  }) async {
    return _execute(
      () => _dio.post(path, data: data, queryParameters: queryParams),
    );
  }

  Future<ApiResponse> put(String path, {Object? data}) async {
    return _execute(() => _dio.put(path, data: data));
  }

  Future<ApiResponse> delete(String path, {Object? data}) async {
    return _execute(() => _dio.delete(path, data: data));
  }

  // ── Internal execution with error mapping ────────────────

  Future<ApiResponse> _execute(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return ApiResponse(
        statusCode: response.statusCode ?? 200,
        data: response.data,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on SocketException {
      throw const ApiException.noNetwork();
    }
  }

  ApiException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException.timeout();
    }

    if (e.type == DioExceptionType.connectionError) {
      return const ApiException.noNetwork();
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final message = _extractMessage(data) ?? e.message ?? 'Unknown error';

    switch (statusCode) {
      case 401:
        return ApiException.unauthorized(message);
      case 403:
        // Check for device revocation
        final reason = _extractReason(data);
        if (reason == 'device_revoked' || message.contains('revoked')) {
          return ApiException.deviceRevoked(message);
        }
        return ApiException.forbidden(message);
      case 409:
        return ApiException.conflict(message, data: data);
      case 422:
        return ApiException.validation(
          message,
          validationErrors: _extractErrors(data),
        );
      case 429:
        final retryAfter = e.response?.headers['retry-after']?.first;
        return ApiException.rateLimited(
          message,
          retryAfterSeconds: retryAfter != null
              ? int.tryParse(retryAfter)
              : null,
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return ApiException.server(message, statusCode: statusCode);
        }
        return ApiException(
          type: ApiExceptionType.unknown,
          message: message,
          statusCode: statusCode,
        );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }

  String? _extractReason(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['reason'] as String?;
    }
    return null;
  }

  Map<String, List<String>>? _extractErrors(dynamic data) {
    if (data is Map<String, dynamic> && data['errors'] is Map) {
      final raw = data['errors'] as Map<String, dynamic>;
      return raw.map(
        (k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()),
      );
    }
    return null;
  }
}

// ── Auth interceptor ──────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final SecureStorageContract _secureStorage;

  _AuthInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(StorageKeys.authToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final deviceUuid = await _secureStorage.read(StorageKeys.deviceUuid);
    if (deviceUuid != null && deviceUuid.isNotEmpty) {
      options.headers['X-Device-ID'] = deviceUuid;
    }

    handler.next(options);
  }
}

// ── Response / Exception types ────────────────────────────────

class ApiResponse {
  final int statusCode;
  final dynamic data;

  const ApiResponse({required this.statusCode, this.data});

  Map<String, dynamic> get json =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : {};
}

enum ApiExceptionType {
  noNetwork,
  timeout,
  unauthorized,
  deviceRevoked,
  forbidden,
  validation,
  conflict,
  rateLimited,
  server,
  serialization,
  unknown,
}

class ApiException implements Exception {
  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? validationErrors;
  final int? retryAfterSeconds;
  final dynamic data;

  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.validationErrors,
    this.retryAfterSeconds,
    this.data,
  });

  const ApiException.noNetwork()
    : type = ApiExceptionType.noNetwork,
      message = 'No network connection',
      statusCode = null,
      validationErrors = null,
      retryAfterSeconds = null,
      data = null;

  const ApiException.timeout()
    : type = ApiExceptionType.timeout,
      message = 'Request timed out',
      statusCode = null,
      validationErrors = null,
      retryAfterSeconds = null,
      data = null;

  ApiException.unauthorized(this.message)
    : type = ApiExceptionType.unauthorized,
      statusCode = 401,
      validationErrors = null,
      retryAfterSeconds = null,
      data = null;

  ApiException.deviceRevoked(this.message)
    : type = ApiExceptionType.deviceRevoked,
      statusCode = 403,
      validationErrors = null,
      retryAfterSeconds = null,
      data = null;

  ApiException.forbidden(this.message)
    : type = ApiExceptionType.forbidden,
      statusCode = 403,
      validationErrors = null,
      retryAfterSeconds = null,
      data = null;

  ApiException.validation(this.message, {this.validationErrors})
    : type = ApiExceptionType.validation,
      statusCode = 422,
      retryAfterSeconds = null,
      data = null;

  ApiException.conflict(this.message, {this.data})
    : type = ApiExceptionType.conflict,
      statusCode = 409,
      validationErrors = null,
      retryAfterSeconds = null;

  ApiException.rateLimited(this.message, {this.retryAfterSeconds})
    : type = ApiExceptionType.rateLimited,
      statusCode = 429,
      validationErrors = null,
      data = null;

  ApiException.server(this.message, {this.statusCode = 500})
    : type = ApiExceptionType.server,
      validationErrors = null,
      retryAfterSeconds = null,
      data = null;

  /// Whether this exception represents a transient failure eligible for retry.
  bool get isRetryable =>
      type == ApiExceptionType.noNetwork ||
      type == ApiExceptionType.timeout ||
      type == ApiExceptionType.server ||
      type == ApiExceptionType.rateLimited;

  @override
  String toString() => 'ApiException($type, $statusCode: $message)';
}
