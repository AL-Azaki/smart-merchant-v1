import 'package:drift/drift.dart';

/// Drift ORM table definition for `order_items` (Domain 5 - Sales).
///
/// Line items for sales orders.
@DataClassName('OrderItemEntity')
class OrderItems extends Table {
  @override
  String get tableName => 'order_items';

  /// Primary key (`uuid`).
  TextColumn get id => text()();

  /// Composite Foreign Key part linking to `businesses.id`.
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to `orders(business_id, id)` (CASCADE).
  TextColumn get orderId => text().named('order_id')();

  /// Composite Foreign Key linking to `product_units(business_id, id)` (RESTRICT).
  TextColumn get productUnitId => text().named('product_unit_id')();

  /// Ordered quantity (`decimal(18,3)`).
  RealColumn get quantity => real()();

  /// Unit price (`decimal(18,2)`).
  RealColumn get unitPrice => real().named('unit_price')();

  /// Discount applied to the line (`decimal(18,2)`).
  RealColumn get discount => real().withDefault(const Constant(0.00))();

  /// Tax applied to the line (`decimal(18,2)`).
  RealColumn get tax => real().withDefault(const Constant(0.00))();

  /// Total amount for the line item after discount and tax (`decimal(18,2)`).
  RealColumn get lineTotal => real().named('line_total')();

  /// Line total converted to base currency (`decimal(18,2)`).
  RealColumn get baseLineTotal =>
      real().named('base_line_total').withDefault(const Constant(0.00))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, order_id) REFERENCES orders(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT',
  ];
}
