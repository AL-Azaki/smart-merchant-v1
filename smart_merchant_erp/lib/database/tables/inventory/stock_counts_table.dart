import 'package:drift/drift.dart';
import '../../converters/stock_count_status_converter.dart';
import '../../enums/stock_count_status.dart';

@DataClassName('StockCount')
class StockCounts extends Table {
  @override
  String get tableName => 'stock_counts';

  TextColumn get id => text()();

  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint('NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT')();

  TextColumn get branchId => text()
      .named('branch_id')
      .customConstraint('NOT NULL REFERENCES branches(id) ON DELETE RESTRICT')();

  TextColumn get warehouseId => text()
      .named('warehouse_id')
      .customConstraint('NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT')();

  TextColumn get countNumber => text().named('count_number')();

  DateTimeColumn get countDate => dateTime().named('count_date').withDefault(currentDateAndTime)();

  TextColumn get status => text()
      .map(const StockCountStatusConverter())
      .withDefault(const Constant('Draft'))();

  TextColumn get notes => text().nullable()();

  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  TextColumn get postedBy => text()
      .named('posted_by')
      .customConstraint('REFERENCES users(id) ON DELETE RESTRICT')
      .nullable()();

  DateTimeColumn get postedAt => dateTime().named('posted_at').nullable()();

  TextColumn get syncStatus => text().named('sync_status').withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, countNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Draft\', \'Posted\', \'Cancelled\'))',
  ];
}
