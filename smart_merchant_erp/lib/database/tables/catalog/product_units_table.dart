import 'package:drift/drift.dart';

/// Drift table definition for `product_units`.
///
/// Purpose: Product-unit combinations with pricing and conversion ratios. Each product can have multiple units (e.g., Piece, Box of 12).
/// Domain: DOMAIN 2 — CATALOG
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as product units are created and managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
///
/// Note on Partial Unique Index:
/// `uq_product_units_one_base ON product_units (product_id) WHERE is_base_unit = true`
/// ensures at most one base unit per product.
@DataClassName('ProductUnit')
@TableIndex(
  name: 'uq_product_units_one_base',
  columns: {#productId},
  unique: true,
)
class ProductUnits extends Table {
  @override
  String get tableName => 'product_units';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `products(business_id, id)` (CASCADE).
  TextColumn get productId => text().named('product_id')();

  /// Foreign Key linking to `units.id` (RESTRICT).
  TextColumn get unitId => text()
      .named('unit_id')
      .customConstraint('NOT NULL REFERENCES units(id) ON DELETE RESTRICT')();

  /// Stock Keeping Unit reference code.
  TextColumn get sku => text().nullable()();

  /// Barcode string (EAN/UPC/QR).
  TextColumn get barcode => text().nullable()();

  /// Multiplier conversion factor relative to the product base unit (`decimal(18,4)`, check > 0).
  RealColumn get conversionFactor =>
      real().named('conversion_factor').withDefault(const Constant(1.0000))();

  /// Default cost/purchase price per unit (`decimal(18,2)`, check >= 0).
  RealColumn get purchasePrice =>
      real().named('purchase_price').withDefault(const Constant(0.00))();

  /// Default retail/selling price per unit (`decimal(18,2)`).
  RealColumn get sellingPrice =>
      real().named('selling_price').withDefault(const Constant(0.00))();

  /// Floor/minimum allowed selling price per unit (`decimal(18,2)`).
  RealColumn get minimumPrice =>
      real().named('minimum_price').withDefault(const Constant(0.00))();

  /// Flag indicating if this unit is the base conversion unit (`is_base_unit`).
  BoolColumn get isBaseUnit =>
      boolean().named('is_base_unit').withDefault(const Constant(false))();

  /// Operational activity status flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  /// Record creation timestamp.
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  /// Soft delete timestamp (`deleted_at`).
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the product unit record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, barcode},
    {businessId, sku},
    {productId, unitId},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, product_id) REFERENCES products(business_id, id) ON DELETE CASCADE',
    'CHECK (conversion_factor > 0)',
    'CHECK (purchase_price >= 0 AND selling_price >= minimum_price AND minimum_price >= 0)',
  ];
}
