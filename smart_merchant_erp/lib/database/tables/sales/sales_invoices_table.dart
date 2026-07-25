import 'package:drift/drift.dart';

/// Drift table definition for `sales_invoices`.
///
/// Purpose: Sales invoice headers with multi-currency support and dual totals.
/// Domain: DOMAIN 5 — SALES & CUSTOMERS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as sales invoices are issued daily from local POS and devices (Offline-First Source of Truth) and synced bidirectionally.
@DataClassName('SalesInvoice')
@TableIndex(
  name: 'idx_sales_invoices_status',
  columns: {#status, #paymentStatus},
)
class SalesInvoices extends Table {
  @override
  String get tableName => 'sales_invoices';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `branches(business_id, id)`.
  TextColumn get branchId => text().named('branch_id')();

  /// Composite Foreign Key linking to `customers(business_id, id)` (nullable for walk-in customers).
  TextColumn get customerId => text().named('customer_id').nullable()();

  /// Unique invoice tracking number per business.
  TextColumn get invoiceNumber => text().named('invoice_number')();

  /// Invoice issuance timestamp (`CURRENT_TIMESTAMP`).
  DateTimeColumn get invoiceDate =>
      dateTime().named('invoice_date').withDefault(currentDateAndTime)();

  /// Invoice due date timestamp (nullable).
  DateTimeColumn get dueDate => dateTime().named('due_date').nullable()();

  /// Foreign Key linking to applied transaction currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Currency conversion exchange rate applied at invoice time (`decimal(18,8)`).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.00000000))();

  /// Invoice sub-total in transaction currency (`decimal(18,2)`).
  RealColumn get subTotal =>
      real().named('sub_total').withDefault(const Constant(0.00))();

  /// Total applied discounts in transaction currency (`decimal(18,2)`).
  RealColumn get discountTotal =>
      real().named('discount_total').withDefault(const Constant(0.00))();

  /// Total calculated taxes in transaction currency (`decimal(18,2)`).
  RealColumn get taxTotal =>
      real().named('tax_total').withDefault(const Constant(0.00))();

  /// Final invoice grand total in transaction currency (`decimal(18,2)`).
  RealColumn get grandTotal =>
      real().named('grand_total').withDefault(const Constant(0.00))();

  /// Invoice sub-total in system base currency (`decimal(18,2)`).
  RealColumn get baseSubTotal =>
      real().named('base_sub_total').withDefault(const Constant(0.00))();

  /// Total discounts in system base currency (`decimal(18,2)`).
  RealColumn get baseDiscountTotal =>
      real().named('base_discount_total').withDefault(const Constant(0.00))();

  /// Total taxes in system base currency (`decimal(18,2)`).
  RealColumn get baseTaxTotal =>
      real().named('base_tax_total').withDefault(const Constant(0.00))();

  /// Final invoice grand total in system base currency (`decimal(18,2)`).
  RealColumn get baseGrandTotal =>
      real().named('base_grand_total').withDefault(const Constant(0.00))();

  /// Invoice settlement payment status (`Unpaid`, `Partial`, `Paid`).
  TextColumn get paymentStatus =>
      text().named('payment_status').withDefault(const Constant('Unpaid'))();

  /// Lifecycle status of the invoice (`Draft`, `Posted`, `Reversed`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Draft'))();

  /// General notes and remarks on the invoice.
  TextColumn get notes => text().nullable()();

  /// Foreign Key linking to the user who created the invoice (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

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

  /// Identifier of the device where the sales invoice record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, branchId, invoiceNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, customer_id) REFERENCES customers(business_id, id) ON DELETE RESTRICT',
    'CHECK (payment_status IN (\'Unpaid\', \'Partial\', \'Paid\'))',
    'CHECK (status IN (\'Draft\', \'Posted\', \'Reversed\'))',
  ];
}
