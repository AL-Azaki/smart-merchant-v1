import 'package:drift/drift.dart';

/// Drift table definition for `branch_product_prices`.
///
/// Purpose: Branch-specific price overrides and POS price configurations for product units.
/// Domain: DOMAIN 2 — CATALOG
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as branch pricing rules are created and managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('BranchProductPrice')
class BranchProductPrices extends Table {
  @override
  String get tableName => 'branch_product_prices';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to `branches(business_id, id)` (CASCADE).
  TextColumn get branchId => text().named('branch_id')();

  /// Composite Foreign Key linking to `product_units(business_id, id)` (CASCADE).
  TextColumn get productUnitId => text().named('product_unit_id')();

  /// Branch-specific cost/purchase price per unit (`decimal(18,2)`, check >= 0).
  RealColumn get purchasePrice =>
      real().named('purchase_price').withDefault(const Constant(0.00))();

  /// Branch-specific retail/selling price per unit (`decimal(18,2)`).
  RealColumn get sellingPrice =>
      real().named('selling_price').withDefault(const Constant(0.00))();

  /// Branch-specific floor/minimum allowed selling price per unit (`decimal(18,2)`).
  RealColumn get minimumPrice =>
      real().named('minimum_price').withDefault(const Constant(0.00))();

  /// Operational status flag indicating if this price override is active (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

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

  /// Identifier of the device where the price override record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {branchId, productUnitId},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE CASCADE',
    'CHECK (purchase_price >= 0 AND selling_price >= minimum_price AND minimum_price >= 0)',
  ];
}
