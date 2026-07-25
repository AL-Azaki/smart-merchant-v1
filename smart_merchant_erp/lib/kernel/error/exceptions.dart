/// Base exception thrown by data sources when low-level operations fail.
abstract class AppException implements Exception {
  final String message;
  final int? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

/// Thrown by remote data sources during server or API errors.
class ServerException extends AppException {
  const ServerException(super.message, [super.code]);
}

/// Thrown by local data sources during SQLite / Drift query or storage errors.
class LocalDatabaseException extends AppException {
  const LocalDatabaseException(super.message, [super.code]);
}

/// Thrown during cache read/write operations.
class CacheException extends AppException {
  const CacheException(super.message, [super.code]);
}

/// Thrown when authentication token is invalid or missing.
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, [super.code]);
}
