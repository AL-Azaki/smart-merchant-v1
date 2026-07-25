import 'package:drift/drift.dart';

/// Drift table definition for `customers`.
///
/// Purpose: Customer master data with credit terms, opening balances, and linked accounting accounts.
/// Domain: DOMAIN 5 — SALES & CUSTOMERS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as customer profiles and balances are created and managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('Customer')
class Customers extends Table {
  @override
  String get tableName => 'customers';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Full descriptive customer or company display name.
  TextColumn get customerName => text().named('customer_name')();

  /// Primary contact phone number.
  TextColumn get phone => text().nullable()();

  /// Contact email address.
  TextColumn get email => text().nullable()();

  /// Physical address or shipping address notes.
  TextColumn get address => text().nullable()();

  /// Maximum credit ceiling allowed for the customer (`decimal(18,2)`, check >= 0).
  RealColumn get creditLimit =>
      real().named('credit_limit').withDefault(const Constant(0.00))();

  /// Foreign Key linking to default invoicing currency (`currencies.id`, SET NULL).
  TextColumn get defaultCurrencyId => text()
      .named('default_currency_id')
      .nullable()
      .customConstraint('NULL REFERENCES currencies(id) ON DELETE SET NULL')();

  /// Composite Foreign Key linking to `payment_terms(business_id, id)` (RESTRICT).
  TextColumn get paymentTermId => text().named('payment_term_id').nullable()();

  /// Composite Foreign Key linking to accounting receivable account (`chart_of_accounts(business_id, id)`, RESTRICT).
  TextColumn get receivableAccountId =>
      text().named('receivable_account_id').nullable()();

  /// Customer opening balance amount (`decimal(18,2)`, check >= 0).
  RealColumn get openingBalance =>
      real().named('opening_balance').withDefault(const Constant(0.00))();

  /// Opening balance classification (`debit` or `credit`).
  TextColumn get openingBalanceType =>
      text().named('opening_balance_type').nullable()();

  /// Date when the opening balance was established (`date`).
  DateTimeColumn get openingBalanceDate =>
      dateTime().named('opening_balance_date').nullable()();

  /// Operational activity status flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

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

  /// Identifier of the device where the customer record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, payment_term_id) REFERENCES payment_terms(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, receivable_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT',
    'CHECK (credit_limit >= 0)',
    'CHECK (opening_balance >= 0)',
    'CHECK (opening_balance_type IN (\'debit\', \'credit\') OR opening_balance_type IS NULL)',
  ];
}
