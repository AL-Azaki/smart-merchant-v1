import 'package:drift/drift.dart';

/// Drift table definition for `customer_receivables`.
///
/// Purpose: Accounts Receivable (A/R) sub-ledger tracking open invoices, paid amounts, due dates, and aging per customer.
/// Domain: DOMAIN 5 — SALES & CUSTOMERS (Accounts Receivable)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as accounts receivable records are tracked locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('CustomerReceivable')
class CustomerReceivables extends Table {
  @override
  String get tableName => 'customer_receivables';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `customers(business_id, id)` (RESTRICT).
  TextColumn get customerId => text().named('customer_id')();

  /// Composite Foreign Key linking to `sales_invoices(business_id, id)` (RESTRICT).
  TextColumn get salesInvoiceId => text().named('sales_invoice_id')();

  /// Foreign Key linking to applied transaction currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Currency conversion exchange rate applied (`decimal(18,8)`).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.00000000))();

  /// Original invoice receivable amount in transaction currency (`decimal(18,2)`).
  RealColumn get originalAmount => real().named('original_amount')();

  /// Original invoice receivable amount in system base currency (`decimal(18,2)`).
  RealColumn get baseOriginalAmount => real().named('base_original_amount')();

  /// Total amount settled/paid against this receivable in transaction currency (`decimal(18,2)`).
  RealColumn get paidAmount =>
      real().named('paid_amount').withDefault(const Constant(0.00))();

  /// Total amount settled/paid against this receivable in base currency (`decimal(18,2)`).
  RealColumn get basePaidAmount =>
      real().named('base_paid_amount').withDefault(const Constant(0.00))();

  /// Remaining unpaid balance in transaction currency (`decimal(18,2)`).
  RealColumn get remainingAmount => real().named('remaining_amount')();

  /// Remaining unpaid balance in base currency (`decimal(18,2)`).
  RealColumn get baseRemainingAmount => real().named('base_remaining_amount')();

  /// Invoice settlement due date (`date`).
  DateTimeColumn get dueDate => dateTime().named('due_date').nullable()();

  /// Receivable settlement status (`Unpaid`, `Partial`, `Paid`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Unpaid'))();

  /// Timestamp of the most recent payment allocation against this receivable (`date`).
  DateTimeColumn get lastPaymentDate =>
      dateTime().named('last_payment_date').nullable()();

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

  /// Identifier of the device where the receivable record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, salesInvoiceId},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, customer_id) REFERENCES customers(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, sales_invoice_id) REFERENCES sales_invoices(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Unpaid\', \'Partial\', \'Paid\'))',
  ];
}
