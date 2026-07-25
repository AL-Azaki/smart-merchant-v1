import 'package:drift/drift.dart';

/// Drift table definition for `chart_of_accounts`.
///
/// Purpose: Full chart of accounts with hierarchical parent-child structure. Core of the accounting system.
/// Domain: DOMAIN 4 — FINANCE (Structure & Cash/Bank)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as the chart of accounts structure and accounts are managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('ChartOfAccount')
class ChartOfAccounts extends Table {
  @override
  String get tableName => 'chart_of_accounts';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Self-referential composite Foreign Key linking to parent account (`chart_of_accounts(business_id, id)`, RESTRICT).
  TextColumn get parentAccountId =>
      text().named('parent_account_id').nullable()();

  /// Foreign Key linking to default currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .nullable()
      .customConstraint('NULL REFERENCES currencies(id) ON DELETE RESTRICT')();

  /// Unique account code/number per business (e.g., 1010, 2020).
  TextColumn get accountCode => text().named('account_code')();

  /// Full descriptive name of the account.
  TextColumn get accountName => text().named('account_name')();

  /// Detailed description of the account's purpose.
  TextColumn get description => text().nullable()();

  /// Foreign Key linking to account classification classification (`account_types.id`, RESTRICT).
  IntColumn get accountTypeId => integer()
      .named('account_type_id')
      .customConstraint(
        'NOT NULL REFERENCES account_types(id) ON DELETE RESTRICT',
      )();

  /// General financial category of the account (`account_category`).
  TextColumn get accountCategory =>
      text().named('account_category').nullable()();

  /// Normal accounting balance classification (`Debit` or `Credit`).
  TextColumn get normalBalance => text().named('normal_balance')();

  /// Depth level inside the hierarchical chart of accounts tree (check > 0).
  IntColumn get accountLevel =>
      integer().named('account_level').withDefault(const Constant(1))();

  /// Flag indicating whether direct journal entries can be posted to this account (`allow_posting`).
  BoolColumn get allowPosting =>
      boolean().named('allow_posting').withDefault(const Constant(false))();

  /// Flag indicating if this is a built-in protected system account (`is_system`).
  BoolColumn get isSystem =>
      boolean().named('is_system').withDefault(const Constant(false))();

  /// Operational active status flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

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

  /// Identifier of the device where the account record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, accountCode},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, parent_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT',
    'CHECK (normal_balance IN (\'Debit\', \'Credit\'))',
    'CHECK (account_level > 0)',
  ];
}
