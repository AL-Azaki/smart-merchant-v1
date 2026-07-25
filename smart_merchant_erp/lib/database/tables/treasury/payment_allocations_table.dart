import 'package:drift/drift.dart';

/// Drift table definition for `payment_allocations`.
///
/// Purpose: Allocation/settlement records mapping a payment voucher against open financial documents (invoices, returns).
/// Domain: DOMAIN 7 — FINANCE (Payments & Receipts)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as payment allocations are executed locally inside SQLite (Source of Truth) to close open balances and settle receivables/payables.
@DataClassName('PaymentAllocation')
@TableIndex(
  name: 'idx_payment_allocations_doc',
  columns: {#documentType, #documentId},
)
class PaymentAllocations extends Table {
  @override
  String get tableName => 'payment_allocations';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `payments(business_id, id)` (CASCADE).
  TextColumn get paymentId => text().named('payment_id')();

  /// Allocated settlement amount applied to the document (`decimal(18,2)`, check > 0).
  RealColumn get amount => real()();

  /// Polymorphic document type linking the allocation to the target operational document (`string(50)`).
  TextColumn get documentType => text().named('document_type')();

  /// Polymorphic document ID linking the allocation to the target operational document (e.g., invoice UUID).
  TextColumn get documentId => text().named('document_id')();

  /// Foreign Key linking to the user who performed the allocation (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Record creation timestamp (`timestamp`).
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp (`timestamp`).
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the payment allocation record was created (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, payment_id) REFERENCES payments(business_id, id) ON DELETE CASCADE',
    'CHECK (amount > 0)',
  ];
}
