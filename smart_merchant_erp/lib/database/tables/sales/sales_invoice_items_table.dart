import 'package:drift/drift.dart';

/// Drift table definition for `sales_invoice_items`.
///
/// Purpose: Line items for sales invoices with cost tracking and optional order item linkage.
/// Domain: DOMAIN 5 — SALES & CUSTOMERS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as invoice line items are created and managed directly with invoice headers in local SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('SalesInvoiceItem')
class SalesInvoiceItems extends Table {
  @override
  String get tableName => 'sales_invoice_items';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to `sales_invoices(business_id, id)` (CASCADE).
  TextColumn get salesInvoiceId => text().named('sales_invoice_id')();

  /// Foreign Key linking to `order_items.id` (SET NULL).
  TextColumn get orderItemId => text()
      .named('order_item_id')
      .nullable()
      .customConstraint('NULL REFERENCES order_items(id) ON DELETE SET NULL')();

  /// Composite Foreign Key linking to `product_units(business_id, id)` (RESTRICT).
  TextColumn get productUnitId => text().named('product_unit_id')();

  /// Composite Foreign Key linking to `warehouses(business_id, id)` (RESTRICT).
  TextColumn get warehouseId => text().named('warehouse_id')();

  /// Reference to tax rate UUID (nullable, without formal FK constraint as per specification).
  TextColumn get taxId => text().named('tax_id').nullable()();

  /// Invoiced quantity (`decimal(18,3)` stored as REAL, check > 0).
  RealColumn get quantity => real()();

  /// Unit selling price (`decimal(18,2)` stored as REAL, check >= 0).
  RealColumn get unitPrice => real().named('unit_price')();

  /// Unit cost price (`decimal(18,2)` stored as REAL).
  RealColumn get costPrice =>
      real().named('cost_price').withDefault(const Constant(0.00))();

  /// Applied line item discount (`decimal(18,2)` stored as REAL, check >= 0).
  RealColumn get discount => real().withDefault(const Constant(0.00))();

  /// Calculated line item tax (`decimal(18,2)` stored as REAL).
  RealColumn get tax => real().withDefault(const Constant(0.00))();

  /// Net line item total in transaction currency (`decimal(18,2)`).
  RealColumn get lineTotal => real().named('line_total')();

  /// Total cost value for the line item (`decimal(18,2)`).
  RealColumn get costTotal =>
      real().named('cost_total').withDefault(const Constant(0.00))();

  /// Net line item total converted to system base currency (`decimal(18,2)`).
  RealColumn get baseLineTotal =>
      real().named('base_line_total').withDefault(const Constant(0.00))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the invoice item record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, sales_invoice_id) REFERENCES sales_invoices(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT',
    'CHECK (quantity > 0)',
    'CHECK (unit_price >= 0)',
    'CHECK (discount >= 0)',
  ];
}
