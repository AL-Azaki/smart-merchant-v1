import 'package:drift/drift.dart';

/// Drift table definition for `fiscal_years`.
///
/// Purpose: Accounting fiscal year definitions per business.
/// Domain: DOMAIN 4 — FINANCE (Structure & Cash/Bank)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as fiscal years are defined and managed locally in SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('FiscalYear')
class FiscalYears extends Table {
  @override
  String get tableName => 'fiscal_years';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Unique short fiscal year code (e.g., FY-2026).
  TextColumn get fiscalYearCode => text().named('fiscal_year_code')();

  /// Full descriptive name of the fiscal year.
  TextColumn get fiscalYearName => text().named('fiscal_year_name')();

  /// Detailed description or notes for the fiscal year.
  TextColumn get description => text().nullable()();

  /// Fiscal year start date (`date` stored as INTEGER/DateTime).
  DateTimeColumn get startDate => dateTime().named('start_date')();

  /// Fiscal year end date (`date` stored as INTEGER/DateTime, check end_date > start_date).
  DateTimeColumn get endDate => dateTime().named('end_date')();

  /// Operational status of the fiscal year (`Open` or `Closed`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Open'))();

  /// Record creation timestamp.
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the fiscal year record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, fiscalYearCode},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (status IN (\'Open\', \'Closed\'))',
    'CHECK (end_date > start_date)',
  ];
}
