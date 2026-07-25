import 'package:drift/drift.dart';

/// Drift table definition for `taxes`.
///
/// Purpose: Tax rates definitions per business (e.g., VAT 15%, Zero-Rated) used across products and transactions.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS / CATALOG (Pricing & Taxes)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as tax rate definitions are created and managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('Tax')
class Taxes extends Table {
  @override
  String get tableName => 'taxes';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Display name of the tax rule (e.g., `Value Added Tax 15%`).
  TextColumn get taxName => text().named('tax_name')();

  /// Unique internal reference code within the business (e.g., `VAT_15`).
  TextColumn get taxCode => text().named('tax_code')();

  /// Tax rate percentage or fixed value (`decimal(8,4)` stored as REAL, check >= 0).
  RealColumn get rate => real()();

  /// Calculation method classification (`Percentage`, `Fixed`).
  TextColumn get taxType =>
      text().named('tax_type').withDefault(const Constant('Percentage'))();

  /// Default transaction application flag (`is_default`).
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();

  /// Operational status flag indicating if the tax definition is active (`is_active`).
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

  /// Identifier of the device where the tax record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, taxCode},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (rate >= 0)',
    'CHECK (tax_type IN (\'Percentage\', \'Fixed\'))',
  ];
}
