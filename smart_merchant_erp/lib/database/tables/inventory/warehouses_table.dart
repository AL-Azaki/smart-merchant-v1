import 'package:drift/drift.dart';

/// Drift table definition for `warehouses`.
///
/// Purpose: Storage locations linked to a branch. Each branch can have a default warehouse.
/// Domain: DOMAIN 3 — INVENTORY
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as warehouses are operational local entities created/edited across branches and synced bidirectionally.
@DataClassName('Warehouse')
class Warehouses extends Table {
  @override
  String get tableName => 'warehouses';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `branches(id)` (RESTRICT).
  TextColumn get branchId => text()
      .named('branch_id')
      .customConstraint(
        'NOT NULL REFERENCES branches(id) ON DELETE RESTRICT',
      )();

  /// Name of the warehouse storage location.
  TextColumn get warehouseName => text().named('warehouse_name')();

  /// Unique reference code of the warehouse within the business.
  TextColumn get warehouseCode => text().named('warehouse_code')();

  /// Physical address or location details of the warehouse.
  TextColumn get address => text().nullable()();

  /// Flag indicating if this warehouse is the default storage location for the linked branch.
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();

  /// Operational status flag indicating if the warehouse is active and available for movements.
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

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

  /// Identifier of the device where the warehouse record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, warehouseCode},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
  ];
}
