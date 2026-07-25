import 'package:drift/drift.dart';

/// Drift table definition for `accounting_periods`.
///
/// Purpose: Financial accounting period close status management preventing modification of closed period data.
/// Domain: DOMAIN 9 — SPECIALIZED MODULES & LEDGERS (Financial Closing)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as period closing and locking status controls local posting privileges and must be synced bidirectionally across devices.
@DataClassName('AccountingPeriod')
class AccountingPeriods extends Table {
  @override
  String get tableName => 'accounting_periods';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `fiscal_years(business_id, id)` (RESTRICT).
  TextColumn get fiscalYearId => text().named('fiscal_year_id')();

  /// Sequence number of the accounting period within the fiscal year.
  IntColumn get periodNumber => integer().named('period_number')();

  /// Descriptive name of the accounting period (e.g., January 2026).
  TextColumn get periodName => text().named('period_name')();

  /// Accounting period start date (`date`).
  DateTimeColumn get startDate => dateTime().named('start_date')();

  /// Accounting period end date (`date`, check end_date >= start_date).
  DateTimeColumn get endDate => dateTime().named('end_date')();

  /// Closing status (`Open`, `Closed`, `Locked`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Open'))();

  /// Foreign Key linking to the user who closed or locked the period (`users.id`, SET NULL).
  TextColumn get closedBy => text()
      .named('closed_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

  /// Timestamp when the period was closed or locked.
  DateTimeColumn get closedAt => dateTime().named('closed_at').nullable()();

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

  /// Identifier of the device where the accounting period record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, fiscalYearId, periodNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, fiscal_year_id) REFERENCES fiscal_years(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Open\', \'Closed\', \'Locked\'))',
    'CHECK (end_date >= start_date)',
  ];
}
