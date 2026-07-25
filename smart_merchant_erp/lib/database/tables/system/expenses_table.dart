import 'package:drift/drift.dart';

/// Drift table definition for `expenses`.
///
/// Purpose: Individual expense records with category, payment method, and multi-currency support.
/// Domain: DOMAIN 7 — FINANCE (Expenses)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as daily expenses are entered locally across POS branches and deducted from cash/bank accounts, requiring immediate sync.
@DataClassName('Expense')
class Expenses extends Table {
  @override
  String get tableName => 'expenses';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key component linking to `branches(business_id, id)`.
  TextColumn get branchId => text().named('branch_id')();

  /// Composite Foreign Key component linking to `expense_categories(business_id, id)`.
  TextColumn get expenseCategoryId => text().named('expense_category_id')();

  /// Unique expense transaction/voucher number (`string(50)`).
  TextColumn get expenseNumber => text().named('expense_number')();

  /// Date and time when the expense occurred (`timestamp`, default `CURRENT_TIMESTAMP`).
  DateTimeColumn get expenseDate =>
      dateTime().named('expense_date').withDefault(currentDateAndTime)();

  /// Composite Foreign Key component linking to `payment_methods(business_id, id)`.
  TextColumn get paymentMethodId => text().named('payment_method_id')();

  /// Foreign Key linking to transaction currency `currencies.id` (RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Exchange rate against system base currency (`decimal(18,8)`, default `1.00000000`).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.00000000))();

  /// Total expense amount in transaction currency (`decimal(18,2)`).
  RealColumn get amount => real()();

  /// Total expense amount converted to system base currency (`decimal(18,2)`).
  RealColumn get baseAmount => real().named('base_amount')();

  /// Total tax or VAT amount included/calculated (`decimal(18,2)`, default `0.00`).
  RealColumn get taxAmount =>
      real().named('tax_amount').withDefault(const Constant(0.00))();

  /// External invoice or vendor reference tracking number (`string(100)`, nullable).
  TextColumn get referenceNumber =>
      text().named('reference_number').nullable()();

  /// Document lifecycle status (`Draft`, `Posted`, `Cancelled`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Draft'))();

  /// Additional notes and remarks (`text`, nullable).
  TextColumn get notes => text().nullable()();

  /// Foreign Key linking to the user who created the expense record (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Record creation timestamp (`timestamp`).
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp (`timestamp`).
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  /// Soft delete timestamp (`deleted_at`).
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the expense record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, expenseNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, expense_category_id) REFERENCES expense_categories(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, payment_method_id) REFERENCES payment_methods(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Draft\', \'Posted\', \'Cancelled\'))',
  ];
}
