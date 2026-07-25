import 'package:drift/drift.dart';

/// Drift table definition for `units`.
///
/// Purpose: Units of measurement definitions (e.g., Piece, Kg, Box) scoped per business.
/// Domain: DOMAIN 2 — CATALOG
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as units of measurement are managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('Unit')
class Units extends Table {
  @override
  String get tableName => 'units';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Full unit name (e.g., Kilogram, Piece).
  TextColumn get unitName => text().named('unit_name')();

  /// Short unit symbol representation (e.g., KG, PC).
  TextColumn get unitSymbol => text().named('unit_symbol')();

  /// Detailed measurement description or notes.
  TextColumn get unitDescription =>
      text().named('unit_description').nullable()();

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

  /// Identifier of the device where the unit record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, unitName},
    {businessId, unitSymbol},
  ];
}
