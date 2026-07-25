import 'package:drift/drift.dart';

/// Drift table definition for `purchase_invoice_items`.
///
/// Purpose: Line items for purchase invoices.
/// Domain: DOMAIN 4 — PURCHASING & SUPPLIERS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as purchase invoice line items are recorded and managed with invoice headers locally in SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('PurchaseInvoiceItem')
class PurchaseInvoiceItems extends Table {
  @override
  String get tableName => 'purchase_invoice_items';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to `purchase_invoices(business_id, id)` (CASCADE).
  TextColumn get purchaseInvoiceId => text().named('purchase_invoice_id')();

  /// Composite Foreign Key linking to `product_units(business_id, id)` (RESTRICT).
  TextColumn get productUnitId => text().named('product_unit_id')();

  /// Composite Foreign Key linking to `warehouses(business_id, id)` (RESTRICT).
  TextColumn get warehouseId => text().named('warehouse_id')();

  /// Reference to tax rate UUID (nullable, without formal FK constraint as per specification).
  TextColumn get taxId => text().named('tax_id').nullable()();

  /// Purchased quantity (`decimal(18,3)` stored as REAL, check > 0).
  RealColumn get quantity => real()();

  /// Unit purchasing price (`decimal(18,2)` stored as REAL, check >= 0).
  RealColumn get unitPrice => real().named('unit_price')();

  /// Applied line item discount (`decimal(18,2)` stored as REAL, check >= 0).
  RealColumn get discount => real().withDefault(const Constant(0.00))();

  /// Calculated line item tax (`decimal(18,2)` stored as REAL, check >= 0).
  RealColumn get tax => real().withDefault(const Constant(0.00))();

  /// Net line item total in transaction currency (`decimal(18,2)`, check >= 0).
  RealColumn get lineTotal => real().named('line_total')();

  /// Net line item total converted to system base currency (`decimal(18,2)`).
  RealColumn get baseLineTotal =>
      real().named('base_line_total').withDefault(const Constant(0.00))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the purchase invoice item record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, purchase_invoice_id) REFERENCES purchase_invoices(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT',
    'CHECK (quantity > 0)',
    'CHECK (unit_price >= 0)',
    'CHECK (discount >= 0)',
    'CHECK (tax >= 0)',
    'CHECK (line_total >= 0)',
  ];
}
