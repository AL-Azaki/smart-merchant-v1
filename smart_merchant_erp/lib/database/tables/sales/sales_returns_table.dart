import 'package:drift/drift.dart';

/// Drift table definition for `sales_returns`.
///
/// Purpose: Sales return headers linked to a sales invoice.
/// Domain: DOMAIN 5 — SALES & CUSTOMERS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as sales returns are processed locally against invoices and synced bidirectionally.
@DataClassName('SalesReturn')
class SalesReturns extends Table {
  @override
  String get tableName => 'sales_returns';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `branches(business_id, id)` (RESTRICT).
  TextColumn get branchId => text().named('branch_id')();

  /// Composite Foreign Key linking to original `sales_invoices(business_id, id)` (RESTRICT).
  TextColumn get salesInvoiceId => text().named('sales_invoice_id')();

  /// Unique return document tracking number per business.
  TextColumn get returnNumber => text().named('return_number')();

  /// Return issuance timestamp (`CURRENT_TIMESTAMP`).
  DateTimeColumn get returnDate =>
      dateTime().named('return_date').withDefault(currentDateAndTime)();

  /// Foreign Key linking to applied transaction currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Currency conversion exchange rate applied at return time (`decimal(18,8)`).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.00000000))();

  /// Final return total amount in transaction currency (`decimal(18,2)`).
  RealColumn get totalAmount =>
      real().named('total_amount').withDefault(const Constant(0.00))();

  /// Final return total amount in system base currency (`decimal(18,2)`).
  RealColumn get baseTotalAmount =>
      real().named('base_total_amount').withDefault(const Constant(0.00))();

  /// Lifecycle status of the return (`Draft`, `Posted`, `Reversed`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Draft'))();

  /// General notes and remarks regarding the return reason.
  TextColumn get notes => text().nullable()();

  /// Foreign Key linking to the user who created the return (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Record creation timestamp.
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  /// Soft delete timestamp (`deleted_at`).
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the sales return record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, returnNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, sales_invoice_id) REFERENCES sales_invoices(business_id, id) ON DELETE RESTRICT',
  ];
}
