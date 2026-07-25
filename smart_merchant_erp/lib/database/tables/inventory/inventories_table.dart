import 'package:drift/drift.dart';

/// Drift table definition for `inventories`.
///
/// Purpose: Current stock levels per warehouse per product_unit. Single source of truth for on-hand quantity.
/// Domain: DOMAIN 3 — INVENTORY
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as inventory stock levels change continuously on local POS/branches and require conflict resolution.
@DataClassName('Inventory')
class Inventories extends Table {
  @override
  String get tableName => 'inventories';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Foreign Key linking to `warehouses.id` (RESTRICT).
  TextColumn get warehouseId => text()
      .named('warehouse_id')
      .customConstraint(
        'NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT',
      )();

  /// Foreign Key linking to `product_units.id` (RESTRICT).
  TextColumn get productUnitId => text()
      .named('product_unit_id')
      .customConstraint(
        'NOT NULL REFERENCES product_units(id) ON DELETE RESTRICT',
      )();

  /// Current available on-hand stock quantity (`decimal(18,3)` stored as REAL, check >= 0).
  RealColumn get quantity => real().withDefault(const Constant(0.0))();

  /// Weighted average cost of the product unit in this warehouse (`decimal(18,2)` stored as REAL, check >= 0).
  RealColumn get averageCost =>
      real().named('average_cost').withDefault(const Constant(0.0))();

  /// Minimum threshold quantity that triggers low-stock alerts (`decimal(18,3)` stored as REAL, check >= 0).
  RealColumn get alertQuantity =>
      real().named('alert_quantity').withDefault(const Constant(0.0))();

  /// Record creation timestamp.
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  /// Soft delete timestamp (NULL if active, set when soft deleted).
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the inventory balance record was updated (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, warehouseId, productUnitId},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (quantity >= 0)',
    'CHECK (average_cost >= 0)',
    'CHECK (alert_quantity >= 0)',
  ];
}
