import 'package:drift/drift.dart';

/// Drift table definition for `bank_accounts`.
///
/// Purpose: Business bank accounts with live balances, IBAN information, and reconciliation tracking.
/// Domain: DOMAIN 4 — FINANCE (Structure & Cash/Bank)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as bank account balances and statuses are maintained locally inside SQLite (Source of Truth) and synced across devices.
@DataClassName('BankAccount')
class BankAccounts extends Table {
  @override
  String get tableName => 'bank_accounts';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key linking to `branches(business_id, id)` (RESTRICT, nullable).
  TextColumn get branchId => text().named('branch_id').nullable()();

  /// Foreign Key linking to account currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Bank account number (`string(50)`).
  TextColumn get accountNumber => text().named('account_number')();

  /// International Bank Account Number (`IBAN`, nullable).
  TextColumn get iban => text().nullable()();

  /// Official name of the banking institution (`bank_name`).
  TextColumn get bankName => text().named('bank_name')();

  /// Internal display alias or nick name for the account (`display_name`).
  TextColumn get displayName => text().named('display_name').nullable()();

  /// Additional notes or descriptive details regarding the account.
  TextColumn get description => text().nullable()();

  /// Account operational status (`Active`, `Frozen`, `Closed`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Active'))();

  /// Flag indicating if this account is the system default banking choice (`is_default`).
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();

  /// Initial opening balance recorded at setup (`decimal(18,4)`).
  RealColumn get openingBalance =>
      real().named('opening_balance').withDefault(const Constant(0.0000))();

  /// Date when the initial opening balance was established (`date`).
  DateTimeColumn get openingBalanceDate =>
      dateTime().named('opening_balance_date').nullable()();

  /// Current system ledger balance (`decimal(18,4)`).
  RealColumn get currentBalance =>
      real().named('current_balance').withDefault(const Constant(0.0000))();

  /// Last bank statement balance that was formally reconciled (`decimal(18,4)`).
  RealColumn get lastReconciledBalance =>
      real().named('last_reconciled_balance').nullable()();

  /// Timestamp when the account was last reconciled.
  DateTimeColumn get lastReconciledAt =>
      dateTime().named('last_reconciled_at').nullable()();

  /// Foreign Key linking to the user who created the bank account record (`users.id`, SET NULL).
  TextColumn get createdBy => text()
      .named('created_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

  /// Foreign Key linking to the user who last modified the record (`users.id`, SET NULL).
  TextColumn get updatedBy => text()
      .named('updated_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

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

  /// Identifier of the device where the bank account record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, accountNumber},
    {businessId, iban},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Active\', \'Frozen\', \'Closed\'))',
  ];
}
