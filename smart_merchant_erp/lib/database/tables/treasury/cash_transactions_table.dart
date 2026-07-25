import 'package:drift/drift.dart';

/// Drift table definition for `cash_transactions`.
///
/// Purpose: Individual cash movement records within a cash register.
/// Domain: DOMAIN 4 — FINANCE (Structure & Cash/Bank)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as cash movements, deposits, withdrawals, and POS receipts occur locally inside SQLite (Source of Truth) and sync bidirectionally.
@DataClassName('CashTransaction')
class CashTransactions extends Table {
  @override
  String get tableName => 'cash_transactions';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Foreign Key linking to `cash_registers.id` (CASCADE).
  TextColumn get cashRegisterId => text()
      .named('cash_register_id')
      .customConstraint(
        'NOT NULL REFERENCES cash_registers(id) ON DELETE CASCADE',
      )();

  /// Classification of cash movement (`Deposit`, `Withdrawal`, `Transfer In/Out`, `Adjustment`, `Payment`, `Receipt`).
  TextColumn get transactionType => text().named('transaction_type')();

  /// Transaction amount in register currency (`decimal(15,4)`, check > 0).
  RealColumn get amount => real()();

  /// Polymorphic document type linking cash movement to source document (`document_type`).
  TextColumn get documentType => text().named('document_type').nullable()();

  /// Polymorphic document ID linking cash movement to source document (`document_id`).
  TextColumn get documentId => text().named('document_id').nullable()();

  /// Additional notes or description for the transaction.
  TextColumn get notes => text().nullable()();

  /// Self-referential Foreign Key linking to a related cash transaction (e.g., counterpart in inter-register transfers, SET NULL).
  TextColumn get referenceId => text()
      .named('reference_id')
      .nullable()
      .customConstraint(
        'NULL REFERENCES cash_transactions(id) ON DELETE SET NULL',
      )();

  /// Foreign Key linking to the user who created the transaction (`users.id`, SET NULL).
  TextColumn get createdBy => text()
      .named('created_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

  /// Record creation timestamp (`CURRENT_TIMESTAMP`).
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the cash transaction record was created (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (transaction_type IN (\'Deposit\', \'Withdrawal\', \'Transfer In/Out\', \'Adjustment\', \'Payment\', \'Receipt\'))',
    'CHECK (amount > 0)',
  ];
}
