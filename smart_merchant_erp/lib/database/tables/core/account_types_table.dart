import 'package:drift/drift.dart';

/// Drift table definition for `account_types`.
///
/// Purpose: Lookup table for chart of accounts classification
/// (Assets, Liabilities, Equity, Revenue, Expenses).
/// Domain: DOMAIN 0 — LOOKUP / REFERENCE
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Read-Only lookup table from server. Does not require
/// sync metadata columns (`sync_status`, `version`, `device_id`).
@DataClassName('AccountType')
class AccountTypes extends Table {
  @override
  String get tableName => 'account_types';

  /// Primary Key — standard integer auto-increment (NOT UUID).
  IntColumn get id => integer().autoIncrement()();

  /// English name of the account classification type.
  TextColumn get nameEn => text().named('name_en')();

  /// Arabic name of the account classification type.
  TextColumn get nameAr => text().named('name_ar')();

  /// Unique classification slug (e.g., assets, liabilities).
  TextColumn get slug => text().unique()();

  /// Operational status flag for whether the account classification is active.
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  /// Record creation timestamp.
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
}
