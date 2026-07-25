import 'package:drift/drift.dart';

/// Drift table definition for `bank_reconciliation_lines`.
///
/// Purpose: Individual transaction items checked/cleared or uncleared during a bank reconciliation.
/// Domain: DOMAIN 9 — SPECIALIZED MODULES & LEDGERS (Bank Reconciliations)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as reconciliation line checks/clearances happen locally inside SQLite and sync bidirectionally.
@DataClassName('BankReconciliationLine')
class BankReconciliationLines extends Table {
  @override
  String get tableName => 'bank_reconciliation_lines';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to parent header `bank_reconciliations(business_id, id)` (CASCADE).
  TextColumn get bankReconciliationId =>
      text().named('bank_reconciliation_id')();

  /// Composite Foreign Key linking to the payment voucher being cleared `payments(business_id, id)` (RESTRICT).
  TextColumn get paymentId => text().named('payment_id')();

  /// Boolean flag indicating whether the payment line item has cleared the bank (`is_cleared`).
  BoolColumn get isCleared =>
      boolean().named('is_cleared').withDefault(const Constant(false))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the reconciliation line record was modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, bank_reconciliation_id) REFERENCES bank_reconciliations(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, payment_id) REFERENCES payments(business_id, id) ON DELETE RESTRICT',
  ];
}
