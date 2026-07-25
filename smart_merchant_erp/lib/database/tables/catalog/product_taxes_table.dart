import 'package:drift/drift.dart';

/// Drift table definition for `product_taxes` (Pivot).
///
/// Purpose: Many-to-many pivot associating product units with applicable tax definitions.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS / CATALOG (Pricing & Taxes)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as product-to-tax assignments are created and managed locally in SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('ProductTax')
class ProductTaxes extends Table {
  @override
  String get tableName => 'product_taxes';

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key linking to `product_units(business_id, id)` (CASCADE).
  TextColumn get productUnitId => text().named('product_unit_id')();

  /// Composite Foreign Key linking to `taxes(business_id, id)` (CASCADE).
  TextColumn get taxId => text().named('tax_id')();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the product-tax association was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {businessId, productUnitId, taxId};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, tax_id) REFERENCES taxes(business_id, id) ON DELETE CASCADE',
  ];
}
