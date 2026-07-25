import 'package:drift/drift.dart';

/// Drift table definition for `product_variants`.
///
/// Purpose: Product attribute options and values (e.g., Size: Large, Color: Red) per product unit.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS / CATALOG (Variants)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as product variant configurations are created and managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('ProductVariant')
class ProductVariants extends Table {
  @override
  String get tableName => 'product_variants';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key linking to `product_units(business_id, id)` (CASCADE).
  TextColumn get productUnitId => text().named('product_unit_id')();

  /// Attribute name (e.g., `Color`, `Size`).
  TextColumn get variantName => text().named('variant_name')();

  /// Attribute value (e.g., `Red`, `XL`).
  TextColumn get variantValue => text().named('variant_value')();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the product variant record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {productUnitId, variantName},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE CASCADE',
  ];
}
