import 'package:drift/drift.dart';

/// Drift table definition for `bank_transactions`.
///
/// Purpose: Individual bank transaction records with multi-currency support and reconciliation tracking.
/// Domain: DOMAIN 4 — FINANCE (Structure & Cash/Bank)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as bank deposits, withdrawals, transfers, and bank fees are recorded locally inside SQLite (Source of Truth) and synced across devices.
@DataClassName('BankTransaction')
@TableIndex(name: 'idx_bt_document', columns: {#documentType, #documentId})
class BankTransactions extends Table {
  @override
  String get tableName => 'bank_transactions';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key linking to `bank_accounts(business_id, id)` (CASCADE).
  TextColumn get bankAccountId => text().named('bank_account_id')();

  /// Classification of bank movement (`Deposit`, `Withdrawal`, `Transfer In/Out`, `Adjustment`, `Bank Fee`, `Interest`, `Opening Balance`).
  TextColumn get transactionType => text().named('transaction_type')();

  /// Direction of financial flow inside the bank account (`Credit` or `Debit`).
  TextColumn get direction => text()();

  /// Transaction amount in bank account currency (`decimal(18,4)`, check > 0).
  RealColumn get amount => real()();

  /// Amount in foreign transaction currency if different from bank account currency (`decimal(18,4)`).
  RealColumn get foreignCurrencyAmount =>
      real().named('foreign_currency_amount').nullable()();

  /// ISO code of the foreign currency (`string(3)`, e.g., USD, EUR).
  TextColumn get foreignCurrencyCode =>
      text().named('foreign_currency_code').nullable()();

  /// Exchange rate applied during currency conversion (`decimal(18,6)`).
  RealColumn get exchangeRate => real().named('exchange_rate').nullable()();

  /// Polymorphic document type linking bank movement to operational source document (`document_type`).
  TextColumn get documentType => text().named('document_type').nullable()();

  /// Polymorphic document ID linking bank movement to operational source document (`document_id`).
  TextColumn get documentId => text().named('document_id').nullable()();

  /// Reference UUID linking to a related bank transfer transaction (`bank_transfer_id`).
  TextColumn get bankTransferId =>
      text().named('bank_transfer_id').nullable()();

  /// Bank statement reconciliation status (`Unreconciled` or reconciled state).
  TextColumn get reconciliationStatus => text()
      .named('reconciliation_status')
      .withDefault(const Constant('Unreconciled'))();

  /// Additional notes or description regarding the bank transaction.
  TextColumn get notes => text().nullable()();

  /// Foreign Key linking to the user who created the bank transaction (`users.id`, SET NULL).
  TextColumn get createdBy => text()
      .named('created_by')
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

  /// Identifier of the device where the bank transaction record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, bank_account_id) REFERENCES bank_accounts(business_id, id) ON DELETE CASCADE',
    'CHECK (transaction_type IN (\'Deposit\', \'Withdrawal\', \'Transfer In/Out\', \'Adjustment\', \'Bank Fee\', \'Interest\', \'Opening Balance\'))',
    'CHECK (direction IN (\'Credit\', \'Debit\'))',
    'CHECK (amount > 0)',
  ];
}
