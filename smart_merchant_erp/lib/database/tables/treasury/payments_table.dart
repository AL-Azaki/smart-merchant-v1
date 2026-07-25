import 'package:drift/drift.dart';

/// Drift table definition for `payments`.
///
/// Purpose: Treasury payment/receipt voucher headers with polymorphic contact linkage and multi-currency support.
/// Domain: DOMAIN 7 — FINANCE (Payments & Receipts)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as receipt and payout vouchers are issued locally in SQLite (Source of Truth) and synced bidirectionally to update central reporting.
@DataClassName('Payment')
@TableIndex(name: 'idx_payments_contact', columns: {#contactType, #contactId})
class Payments extends Table {
  @override
  String get tableName => 'payments';

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

  /// Unique voucher number per business (e.g., RCP-2026-0001, PAY-2026-0001).
  TextColumn get paymentNumber => text().named('payment_number')();

  /// Date and time when the payment voucher was issued (`CURRENT_TIMESTAMP`).
  DateTimeColumn get paymentDate =>
      dateTime().named('payment_date').withDefault(currentDateAndTime)();

  /// Composite Foreign Key linking to `payment_methods(business_id, id)`.
  TextColumn get paymentMethodId => text().named('payment_method_id')();

  /// Composite Foreign Key linking to target bank/cash account (`chart_of_accounts(business_id, id)`).
  TextColumn get chartOfAccountId => text().named('chart_of_account_id')();

  /// Foreign Key linking to transaction currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Currency conversion exchange rate applied during transaction (`decimal(18,8)`).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.00000000))();

  /// Total voucher amount in transaction currency (`decimal(18,2)`).
  RealColumn get amount => real()();

  /// Total voucher amount converted to system base currency (`decimal(18,2)`).
  RealColumn get baseAmount => real().named('base_amount')();

  /// Voucher classification (`Receipt`, `Payment`, `Refund`, `Adjustment`, `Transfer`).
  TextColumn get paymentType => text().named('payment_type')();

  /// Polymorphic contact type classification (`Customer`, `Supplier`, `Employee`, `Other`).
  TextColumn get contactType => text().named('contact_type').nullable()();

  /// Polymorphic contact ID linking voucher to the specific entity (Customer UUID, Supplier UUID, etc.).
  TextColumn get contactId => text().named('contact_id').nullable()();

  /// Lifecycle posting status (`Draft`, `Posted`, `Reversed`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Draft'))();

  /// Additional notes or description for the payment/receipt voucher.
  TextColumn get notes => text().nullable()();

  /// Foreign Key linking to the user who created the voucher (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Foreign Key linking to the user who posted the voucher (`users.id`, RESTRICT).
  TextColumn get postedBy => text()
      .named('posted_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Timestamp when the voucher was officially posted (`timestamp`).
  DateTimeColumn get postedAt => dateTime().named('posted_at').nullable()();

  /// Foreign Key linking to the user who reversed the voucher (`users.id`, RESTRICT).
  TextColumn get reversedBy => text()
      .named('reversed_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Timestamp when the voucher was reversed (`timestamp`).
  DateTimeColumn get reversedAt => dateTime().named('reversed_at').nullable()();

  /// Explanation stating why the voucher was reversed.
  TextColumn get reversalReason => text().named('reversal_reason').nullable()();

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

  /// Identifier of the device where the payment voucher was created (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, paymentNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id)',
    'FOREIGN KEY (business_id, payment_method_id) REFERENCES payment_methods(business_id, id)',
    'FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id)',
    'CHECK (payment_type IN (\'Receipt\', \'Payment\', \'Refund\', \'Adjustment\', \'Transfer\'))',
    'CHECK (contact_type IN (\'Customer\', \'Supplier\', \'Employee\', \'Other\'))',
    'CHECK (status IN (\'Draft\', \'Posted\', \'Reversed\'))',
  ];
}
