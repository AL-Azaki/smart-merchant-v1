import 'package:drift/drift.dart';

/// Drift table definition for `sales_return_items`.
///
/// Purpose: Line items for sales returns, linked to original sales invoice items.
/// Domain: DOMAIN 5 — SALES & CUSTOMERS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as return line items are created locally and synced bidirectionally.
@DataClassName('SalesReturnItem')
class SalesReturnItems extends Table {
  @override
  String get tableName => 'sales_return_items';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to `sales_returns(business_id, id)` (CASCADE).
  TextColumn get salesReturnId => text().named('sales_return_id')();

  /// Foreign Key linking to original invoiced line item (`sales_invoice_items.id`, RESTRICT).
  TextColumn get salesInvoiceItemId => text()
      .named('sales_invoice_item_id')
      .customConstraint(
        'NOT NULL REFERENCES sales_invoice_items(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to receiving `warehouses(business_id, id)` (RESTRICT).
  TextColumn get warehouseId => text().named('warehouse_id')();

  /// Returned quantity (`decimal(18,3)` stored as REAL).
  RealColumn get quantity => real()();

  /// Unit selling price (`decimal(18,2)` stored as REAL).
  RealColumn get unitPrice => real().named('unit_price')();

  /// Unit cost price (`decimal(18,2)` stored as REAL).
  RealColumn get costPrice =>
      real().named('cost_price').withDefault(const Constant(0.00))();

  /// Returned line item total price in transaction currency (`decimal(18,2)`).
  RealColumn get totalPrice => real().named('total_price')();

  /// Total cost value for the returned item (`decimal(18,2)`).
  RealColumn get costTotal =>
      real().named('cost_total').withDefault(const Constant(0.00))();

  /// Returned line item total price converted to system base currency (`decimal(18,2)`).
  RealColumn get baseTotalPrice =>
      real().named('base_total_price').withDefault(const Constant(0.00))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the return item record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, sales_return_id) REFERENCES sales_returns(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT',
  ];
}
