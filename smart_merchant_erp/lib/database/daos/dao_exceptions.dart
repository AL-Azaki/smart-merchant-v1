import '../../kernel/error/exceptions.dart';

/// Thrown when a DAO query is attempted without a required tenant scope (e.g., empty or null businessId).
class TenantScopingException extends LocalDatabaseException {
  const TenantScopingException([
    super.message =
        'Mandatory businessId parameter is empty or null across tenant scope.',
  ]);
}

/// Thrown when a single record lookup or required sequence counter is not found.
class RecordNotFoundException extends LocalDatabaseException {
  const RecordNotFoundException([
    super.message = 'Requested database record was not found.',
  ]);
}

/// Thrown when a database mutation violates a unique constraint (e.g., duplicate barcode or SKU).
class DuplicateRecordException extends LocalDatabaseException {
  const DuplicateRecordException([
    super.message = 'Record violates unique constraint in the local database.',
  ]);
}

/// Thrown when a database mutation violates a foreign key constraint.
class ForeignKeyConstraintException extends LocalDatabaseException {
  const ForeignKeyConstraintException([
    super.message =
        'Record violates foreign key constraint in the local database.',
  ]);
}

/// Thrown when attempting to post a journal entry where debits do not equal credits.
class BalancedJournalRequiredException extends LocalDatabaseException {
  const BalancedJournalRequiredException([
    super.message =
        'Journal entry lines must balance (Total Debits must equal Total Credits).',
  ]);
}
