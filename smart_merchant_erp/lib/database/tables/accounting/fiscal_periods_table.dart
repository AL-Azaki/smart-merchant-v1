import 'package:drift/drift.dart';

/// Drift table definition for `fiscal_periods`.
///
/// Purpose: Monthly periods within a fiscal year (1–12).
/// Domain: DOMAIN 4 — FINANCE (Structure & Cash/Bank)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as fiscal periods and their status are managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('FiscalPeriod')
class FiscalPeriods extends Table {
  @override
  String get tableName => 'fiscal_periods';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to `fiscal_years(business_id, id)` (RESTRICT).
  TextColumn get fiscalYearId => text().named('fiscal_year_id')();

  /// Period sequence number inside the fiscal year (`1–12`).
  IntColumn get periodNumber => integer().named('period_number')();

  /// Descriptive period name (e.g., January 2026).
  TextColumn get periodName => text().named('period_name')();

  /// Period start date (`date` stored as INTEGER/DateTime).
  DateTimeColumn get startDate => dateTime().named('start_date')();

  /// Period end date (`date` stored as INTEGER/DateTime, check end_date > start_date).
  DateTimeColumn get endDate => dateTime().named('end_date')();

  /// Period open/closed status (`Open` or `Closed`).
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

  /// Identifier of the device where the fiscal period record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {fiscalYearId, periodNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, fiscal_year_id) REFERENCES fiscal_years(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Open\', \'Closed\'))',
    'CHECK (period_number BETWEEN 1 AND 12)',
    'CHECK (end_date > start_date)',
  ];
}
