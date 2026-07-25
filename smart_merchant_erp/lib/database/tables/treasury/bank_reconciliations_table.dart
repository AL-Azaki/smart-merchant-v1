import 'package:drift/drift.dart';

/// Drift table definition for `bank_reconciliations`.
///
/// Purpose: Periodic statement reconciliations comparing bank statement balances against system ledger balances.
/// Domain: DOMAIN 9 — SPECIALIZED MODULES & LEDGERS (Bank Reconciliations)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as bank reconciliations are conducted locally inside SQLite (Source of Truth) and synced across devices.
@DataClassName('BankReconciliation')
class BankReconciliations extends Table {
  @override
  String get tableName => 'bank_reconciliations';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `chart_of_accounts(business_id, id)` (RESTRICT).
  TextColumn get chartOfAccountId => text().named('chart_of_account_id')();

  /// Date of the bank statement being reconciled (`date`).
  DateTimeColumn get statementDate => dateTime().named('statement_date')();

  /// Ending balance reported on the official bank statement (`decimal(18,2)`).
  RealColumn get statementBalance => real().named('statement_balance')();

  /// Ending balance calculated by the system general ledger (`decimal(18,2)`).
  RealColumn get systemBalance => real().named('system_balance')();

  /// Calculated discrepancy amount between statement and ledger (`decimal(18,2)`).
  RealColumn get difference => real()();

  /// Status of the reconciliation (`Draft` or `Completed`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Draft'))();

  /// Foreign Key linking to the user who created the reconciliation (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Record creation timestamp (`timestamp`).
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp (`timestamp`).
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the bank reconciliation record was created (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, chartOfAccountId, statementDate},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Draft\', \'Completed\'))',
  ];
}
