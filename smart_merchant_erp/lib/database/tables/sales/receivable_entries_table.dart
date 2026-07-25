import 'package:drift/drift.dart';

/// Drift table definition for `receivable_entries`.
///
/// Purpose: Detailed tracking history of payment allocations against accounts receivable records.
/// Domain: DOMAIN 5 — SALES & CUSTOMERS (Accounts Receivable)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as payment allocation entries are recorded locally in SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('ReceivableEntry')
class ReceivableEntries extends Table {
  @override
  String get tableName => 'receivable_entries';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to `customer_receivables(business_id, id)` (CASCADE).
  TextColumn get customerReceivableId =>
      text().named('customer_receivable_id')();

  /// Composite Foreign Key linking to `payments(business_id, id)` (SET NULL).
  TextColumn get paymentId => text().named('payment_id').nullable()();

  /// Composite Foreign Key linking to `payment_allocations(business_id, id)` (SET NULL).
  TextColumn get paymentAllocationId =>
      text().named('payment_allocation_id').nullable()();

  /// Timestamp when this receivable entry/allocation took place (`CURRENT_TIMESTAMP`).
  DateTimeColumn get entryDate =>
      dateTime().named('entry_date').withDefault(currentDateAndTime)();

  /// Amount allocated or adjusted in transaction currency (`decimal(18,2)`).
  RealColumn get amount => real()();

  /// Amount allocated or adjusted in system base currency (`decimal(18,2)`).
  RealColumn get baseAmount => real().named('base_amount')();

  /// Type of receivable entry (`Payment`, `Adjustment`, `WriteOff`).
  TextColumn get entryType =>
      text().named('entry_type').withDefault(const Constant('Payment'))();

  /// Foreign Key linking to the user who created the entry (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Record creation timestamp (`CURRENT_TIMESTAMP`).
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the receivable entry record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, customer_receivable_id) REFERENCES customer_receivables(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, payment_id) REFERENCES payments(business_id, id) ON DELETE SET NULL',
    'FOREIGN KEY (business_id, payment_allocation_id) REFERENCES payment_allocations(business_id, id) ON DELETE SET NULL',
    'CHECK (entry_type IN (\'Payment\', \'Adjustment\', \'WriteOff\'))',
  ];
}
