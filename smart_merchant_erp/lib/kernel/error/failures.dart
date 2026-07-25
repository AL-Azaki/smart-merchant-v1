import 'package:equatable/equatable.dart';

/// Base class for all application failures.
/// Centralizes error handling across the entire Smart Merchant ERP system.
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

/// Represents failures arising from local SQLite / Drift operations.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.code]);
}

/// Represents failures arising from remote network / API calls or offline disconnects.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

/// Represents failures during user authentication or session validation.
class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

/// Represents validation failures when domain or DTO input invariants are breached.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

/// Represents synchronization engine failures during offline queue processing.
class SyncFailure extends Failure {
  const SyncFailure(super.message, [super.code]);
}

/// Represents unexpected or unhandled exceptions across the application.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, [super.code]);
}

/// Base class for repository-level failures.
class RepositoryFailure extends Failure {
  const RepositoryFailure(super.message, [super.code]);
}

/// Represents tenant (`businessId`) or branch (`branchId`) scoping boundary violations.
class TenantScopeFailure extends Failure {
  const TenantScopeFailure(super.message, [super.code]);
}

/// Represents failures when a requested domain resource or record is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.code]);
}

/// Represents concurrency conflicts, duplicate records, or foreign key constraint violations.
class ConflictFailure extends Failure {
  const ConflictFailure(super.message, [super.code]);
}

/// Represents low-level storage or SQLite persistence execution failures.
class PersistenceFailure extends Failure {
  const PersistenceFailure(super.message, [super.code]);
}
