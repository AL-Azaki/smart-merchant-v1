import 'package:drift/drift.dart';

@DataClassName('StockCountItem')
class StockCountItems extends Table {
  @override
  String get tableName => 'stock_count_items';

  TextColumn get id => text()();

  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint('NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT')();

  TextColumn get stockCountId => text()
      .named('stock_count_id')
      .customConstraint('NOT NULL REFERENCES stock_counts(id) ON DELETE CASCADE')();

  TextColumn get productId => text()
      .named('product_id')
      .customConstraint('NOT NULL REFERENCES products(id) ON DELETE RESTRICT')();

  TextColumn get productUnitId => text()
      .named('product_unit_id')
      .customConstraint('NOT NULL REFERENCES product_units(id) ON DELETE RESTRICT')();

  RealColumn get expectedQuantity => real().named('expected_quantity')();
  
  RealColumn get countedQuantity => real().named('counted_quantity')();
  
  RealColumn get differenceQuantity => real().named('difference_quantity')();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  TextColumn get syncStatus => text().named('sync_status').withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, stock_count_id) REFERENCES stock_counts(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, product_id) REFERENCES products(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT',
  ];
}
