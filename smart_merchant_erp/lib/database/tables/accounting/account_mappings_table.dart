import 'package:drift/drift.dart';

/// Drift table definition for `account_mappings`.
///
/// Purpose: System default posting rules mapping transaction events to chart of accounts (e.g. Sales Tax Payable, Inventory Control).
/// Domain: DOMAIN 9 — SPECIALIZED MODULES & LEDGERS (Account Mappings)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as default posting rules are configured and managed locally inside SQLite and synced across devices.
@DataClassName('AccountMapping')
class AccountMappings extends Table {
  @override
  String get tableName => 'account_mappings';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Unique system identification key for the mapping (e.g., `default_sales_tax`, `inventory_asset`).
  TextColumn get mappingKey => text().named('mapping_key')();

  /// Human-readable description/name for this account mapping rule.
  TextColumn get mappingName => text().named('mapping_name')();

  /// Composite Foreign Key linking to target account (`chart_of_accounts(business_id, id)`, RESTRICT).
  TextColumn get chartOfAccountId => text().named('chart_of_account_id')();

  /// Active operational flag indicating whether this mapping rule is enabled (`is_active`).
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

  /// Identifier of the device where the account mapping record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, mappingKey},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT',
  ];
}
