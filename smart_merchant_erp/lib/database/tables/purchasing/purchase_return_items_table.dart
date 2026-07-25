import 'package:drift/drift.dart';

/// Drift table definition for `purchase_return_items`.
///
/// Purpose: Line items for purchase returns, linked to original purchase invoice items.
/// Domain: DOMAIN 4 — PURCHASING & SUPPLIERS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as return line items are created locally and synced bidirectionally.
@DataClassName('PurchaseReturnItem')
class PurchaseReturnItems extends Table {
  @override
  String get tableName => 'purchase_return_items';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to `purchase_returns(business_id, id)` (CASCADE).
  TextColumn get purchaseReturnId => text().named('purchase_return_id')();

  /// Foreign Key linking to original purchased line item (`purchase_invoice_items.id`, RESTRICT).
  TextColumn get purchaseInvoiceItemId => text()
      .named('purchase_invoice_item_id')
      .customConstraint(
        'NOT NULL REFERENCES purchase_invoice_items(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `warehouses(business_id, id)` (RESTRICT).
  TextColumn get warehouseId => text().named('warehouse_id')();

  /// Returned quantity (`decimal(18,3)` stored as REAL).
  RealColumn get quantity => real()();

  /// Unit purchasing price (`decimal(18,2)` stored as REAL).
  RealColumn get unitPrice => real().named('unit_price')();

  /// Returned line item total price in transaction currency (`decimal(18,2)`).
  RealColumn get lineTotal => real().named('line_total')();

  /// Returned line item total price converted to system base currency (`decimal(18,2)`).
  RealColumn get baseLineTotal =>
      real().named('base_line_total').withDefault(const Constant(0.00))();

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
    'FOREIGN KEY (business_id, purchase_return_id) REFERENCES purchase_returns(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT',
  ];
}
