import 'package:drift/drift.dart';

/// Drift table definition for `product_images`.
///
/// Purpose: Product image gallery with primary image designation and ordering.
/// Domain: DOMAIN 2 — CATALOG
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as product images are created and managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
///
/// Note on Partial Unique Index:
/// `uq_product_images_primary ON product_images (product_id) WHERE is_primary = true`
/// ensures at most one primary display image per product.
@DataClassName('ProductImage')
@TableIndex(
  name: 'uq_product_images_primary',
  columns: {#productId},
  unique: true,
)
class ProductImages extends Table {
  @override
  String get tableName => 'product_images';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `products.id` (CASCADE).
  TextColumn get productId => text()
      .named('product_id')
      .customConstraint('NOT NULL REFERENCES products(id) ON DELETE CASCADE')();

  /// Relative path to the image asset file.
  TextColumn get imagePath => text().named('image_path')();

  /// Flag designating this image as the primary display graphic for the product (`is_primary`).
  BoolColumn get isPrimary =>
      boolean().named('is_primary').withDefault(const Constant(false))();

  /// Record creation timestamp (`CURRENT_TIMESTAMP`).
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the product image record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
