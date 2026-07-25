import 'package:drift/drift.dart';

/// Drift table definition for `inventory_transaction_lines`.
///
/// Purpose: Line items for inventory transactions specifying product, quantity, and cost.
/// Domain: DOMAIN 3 — INVENTORY
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as transaction line items are created locally with transaction headers and synced bidirectionally.
@DataClassName('InventoryTransactionLine')
class InventoryTransactionLines extends Table {
  @override
  String get tableName => 'inventory_transaction_lines';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `inventory_transactions(business_id, id)` (CASCADE).
  TextColumn get inventoryTransactionId => text()
      .named('inventory_transaction_id')
      .customConstraint(
        'NOT NULL REFERENCES inventory_transactions(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key linking to `product_units(business_id, id)` (RESTRICT).
  TextColumn get productUnitId => text()
      .named('product_unit_id')
      .customConstraint(
        'NOT NULL REFERENCES product_units(id) ON DELETE RESTRICT',
      )();

  /// Sequential line item number within the parent inventory transaction.
  IntColumn get lineNumber =>
      integer().named('line_number').withDefault(const Constant(1))();

  /// Stock quantity moved (`decimal(18,3)` stored as REAL, check > 0).
  RealColumn get quantity => real()();

  /// Unit cost price for this movement line (`decimal(18,2)` stored as REAL, check >= 0).
  RealColumn get unitCost =>
      real().named('unit_cost').withDefault(const Constant(0.0))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the transaction line was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, inventory_transaction_id) REFERENCES inventory_transactions(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT',
    'CHECK (quantity > 0)',
    'CHECK (unit_cost >= 0)',
  ];
}
