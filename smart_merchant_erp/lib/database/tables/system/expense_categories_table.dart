import 'package:drift/drift.dart';

/// Drift table definition for `expense_categories`.
///
/// Purpose: Expense classification categories linked to chart of accounts.
/// Domain: DOMAIN 7 — FINANCE (Expenses)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as expense classification categories and chart of account mappings are managed locally inside SQLite (Source of Truth) and synced.
@DataClassName('ExpenseCategory')
class ExpenseCategories extends Table {
  @override
  String get tableName => 'expense_categories';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key component linking to `chart_of_accounts(business_id, id)` (RESTRICT).
  TextColumn get chartOfAccountId => text().named('chart_of_account_id')();

  /// Official category name (`string(100)`).
  TextColumn get categoryName => text().named('category_name')();

  /// Descriptive details regarding the expense category (`text`, nullable).
  TextColumn get description => text().nullable()();

  /// Active status flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the category record was created (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, categoryName},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT',
  ];
}
