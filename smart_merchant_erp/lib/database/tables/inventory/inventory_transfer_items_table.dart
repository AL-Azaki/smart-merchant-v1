import 'package:drift/drift.dart';

/// Drift table definition for `inventory_transfer_items`.
///
/// Purpose: Line items for inventory transfers specifying product, quantity, and cost.
/// Domain: DOMAIN 3 — INVENTORY
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as transfer item quantities are recorded locally with transfer headers and synced bidirectionally.
@DataClassName('InventoryTransferItem')
class InventoryTransferItems extends Table {
  @override
  String get tableName => 'inventory_transfer_items';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `inventory_transfers(business_id, id)` (CASCADE).
  TextColumn get transferId => text()
      .named('transfer_id')
      .customConstraint(
        'NOT NULL REFERENCES inventory_transfers(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key linking to `product_units(business_id, id)` (RESTRICT).
  TextColumn get productUnitId => text()
      .named('product_unit_id')
      .customConstraint(
        'NOT NULL REFERENCES product_units(id) ON DELETE RESTRICT',
      )();

  /// Stock quantity transferred (`decimal(18,3)` stored as REAL, check > 0).
  RealColumn get quantity => real()();

  /// Unit cost price for this transferred item (`decimal(18,2)` stored as REAL, check >= 0).
  RealColumn get unitCost =>
      real().named('unit_cost').withDefault(const Constant(0.0))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the transfer item record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {transferId, productUnitId},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, transfer_id) REFERENCES inventory_transfers(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT',
    'CHECK (quantity > 0)',
    'CHECK (unit_cost >= 0)',
  ];
}
