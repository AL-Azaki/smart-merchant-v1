import 'package:drift/drift.dart';

/// Drift table definition for `categories`.
///
/// Purpose: Product categories with self-referencing parent for hierarchical structure, scoped per business.
/// Domain: DOMAIN 2 — CATALOG
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as categories are created and managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('Category')
class Categories extends Table {
  @override
  String get tableName => 'categories';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Self-referential Composite Foreign Key linking to `categories(business_id, id)` (RESTRICT).
  TextColumn get parentId => text().named('parent_id').nullable()();

  /// Display name of the product category.
  TextColumn get categoryName => text().named('category_name')();

  /// Unique reference code of the product category within the business.
  TextColumn get categoryCode => text().named('category_code').nullable()();

  /// Detailed notes or description of the category.
  TextColumn get description => text().nullable()();

  /// Relative path to the category banner or icon image.
  TextColumn get imagePath => text().named('image_path').nullable()();

  /// Numerical sorting sequence index (`integer`, check >= 0).
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();

  /// Operational activity status flag.
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

  /// Identifier of the device where the category record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, categoryName},
    {businessId, categoryCode},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, parent_id) REFERENCES categories(business_id, id) ON DELETE RESTRICT',
    'CHECK (sort_order >= 0)',
  ];
}
