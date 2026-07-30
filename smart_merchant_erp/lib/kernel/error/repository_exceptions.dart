import 'dart:async';
import 'failures.dart';
import '../../database/daos/dao_exceptions.dart';

/// Base exception for the Repository Layer.
abstract class RepositoryException implements Exception {
  final String message;
  final Object? originalError;

  const RepositoryException(this.message, [this.originalError]);

  @override
  String toString() =>
      '$runtimeType(message: $message, originalError: $originalError)';

  /// Converts this exception to a clean [Failure] object for UseCase/result handling.
  Failure toFailure();
}

/// Thrown when tenant (`businessId`) or branch (`branchId`) isolation constraints are violated or missing.
class RepositoryTenantScopeException extends RepositoryException {
  const RepositoryTenantScopeException([
    super.message = 'Missing or invalid tenant/branch scope.',
    super.originalError,
  ]);

  @override
  Failure toFailure() => TenantScopeFailure(message);
}

/// Thrown when a requested record or resource is not found.
class RepositoryNotFoundException extends RepositoryException {
  const RepositoryNotFoundException([
    super.message = 'Requested resource was not found.',
    super.originalError,
  ]);

  @override
  Failure toFailure() => NotFoundFailure(message);
}

/// Thrown when a unique constraint or concurrency conflict occurs.
class RepositoryConflictException extends RepositoryException {
  const RepositoryConflictException([
    super.message = 'Resource conflict or duplicate record encountered.',
    super.originalError,
  ]);

  @override
  Failure toFailure() => ConflictFailure(message);
}

/// Thrown when domain validation or accounting balance rules are breached.
class RepositoryValidationException extends RepositoryException {
  const RepositoryValidationException([
    super.message = 'Validation failure.',
    super.originalError,
  ]);

  @override
  Failure toFailure() => ValidationFailure(message);
}

/// Thrown when a low-level persistence or SQLite operation fails.
class RepositoryPersistenceException extends RepositoryException {
  const RepositoryPersistenceException([
    super.message = 'Database persistence failure.',
    super.originalError,
  ]);

  @override
  Failure toFailure() => PersistenceFailure(message);
}

/// Guard utility class that intercepts low-level data access exceptions and wraps them
/// cleanly into stable domain-level [RepositoryException] semantics without swallowing.
class RepositoryErrorGuard {
  /// Runs a future `action` and maps any data source / SQLite exception to a [RepositoryException].
  static Future<T> run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RepositoryException {
      rethrow;
    } on TenantScopingException catch (e) {
      throw RepositoryTenantScopeException(e.message, e);
    } on RecordNotFoundException catch (e) {
      throw RepositoryNotFoundException(e.message, e);
    } on DuplicateRecordException catch (e) {
      throw RepositoryConflictException(e.message, e);
    } on ForeignKeyConstraintException catch (e) {
      throw RepositoryConflictException(e.message, e);
    } on BalancedJournalRequiredException catch (e) {
      throw RepositoryValidationException(e.message, e);
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('unique constraint') || str.contains('duplicate')) {
        throw RepositoryConflictException('Unique constraint violation: $e', e);
      } else if (str.contains('foreign key') ||
          str.contains('constraint failed')) {
        throw RepositoryConflictException(
          'Foreign key constraint violation: $e',
          e,
        );
      } else if (str.contains('not found')) {
        throw RepositoryNotFoundException('Record not found: $e', e);
      } else if (str.contains('tenant') || str.contains('businessid')) {
        throw RepositoryTenantScopeException('Tenant scoping failure: $e', e);
      }
      throw RepositoryPersistenceException(e.toString(), e);
    }
  }

  /// Wraps a domain [Stream] and intercepts error events to map them into [RepositoryException].
  static Stream<T> guardStream<T>(Stream<T> stream) {
    return stream.handleError((Object error, StackTrace stackTrace) {
      if (error is RepositoryException) {
        throw error;
      } else if (error is TenantScopingException) {
        throw RepositoryTenantScopeException(error.message, error);
      } else if (error is RecordNotFoundException) {
        throw RepositoryNotFoundException(error.message, error);
      } else if (error is DuplicateRecordException) {
        throw RepositoryConflictException(error.message, error);
      } else if (error is ForeignKeyConstraintException) {
        throw RepositoryConflictException(error.message, error);
      } else if (error is BalancedJournalRequiredException) {
        throw RepositoryValidationException(error.message, error);
      } else {
        final str = error.toString().toLowerCase();
        if (str.contains('unique constraint') || str.contains('duplicate')) {
          throw RepositoryConflictException(
            'Unique constraint violation: $error',
            error,
          );
        } else if (str.contains('foreign key') ||
            str.contains('constraint failed')) {
          throw RepositoryConflictException(
            'Foreign key constraint violation: $error',
            error,
          );
        } else if (str.contains('not found')) {
          throw RepositoryNotFoundException('Record not found: $error', error);
        } else if (str.contains('tenant') || str.contains('businessid')) {
          throw RepositoryTenantScopeException(
            'Tenant scoping failure: $error',
            error,
          );
        }
        throw RepositoryPersistenceException(error.toString(), error);
      }
    });
  }
}
