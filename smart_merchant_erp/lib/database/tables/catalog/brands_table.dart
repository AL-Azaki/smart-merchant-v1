import 'package:drift/drift.dart';

/// Drift table definition for `brands`.
///
/// Purpose: Product manufacturers or brands classification scoped per business.
/// Domain: DOMAIN 2 — CATALOG
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as brands are managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('Brand')
class Brands extends Table {
  @override
  String get tableName => 'brands';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Display name of the brand.
  TextColumn get brandName => text().named('brand_name')();

  /// Detailed description or notes regarding the brand.
  TextColumn get description => text().nullable()();

  /// Relative path to the brand logo graphic image.
  TextColumn get logoPath => text().named('logo_path').nullable()();

  /// Operational activity status flag.
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

  /// Identifier of the device where the brand record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, brandName},
  ];
}
