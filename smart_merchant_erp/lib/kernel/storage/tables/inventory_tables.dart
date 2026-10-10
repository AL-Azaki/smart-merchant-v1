import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// UnitsTable stores measurable packaging units (e.g. Piece, Box, Carton, Kg).
@DataClassName('UnitData')
class UnitsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get nameAr => text().withLength(min: 1, max: 100).unique()();
  TextColumn get code => text().withLength(min: 1, max: 20).unique()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// ProductsTable stores the master catalog definition.
/// All stock quantities for a product are strictly accounted for in its baseUnitId.
@DataClassName('ProductData')
class ProductsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get category => text().nullable().withLength(max: 100)();
  TextColumn get sku => text().nullable().withLength(max: 100)();
  TextColumn get imagePath => text().nullable()();
  
  /// Whether the item is a tracked physical inventory item (true) or a service/charge (false)
  BoolColumn get isStockable => boolean().withDefault(const Constant(true))();
  
  /// Base smallest atomic unit for inventory accounting (e.g. Piece/حبة)
  TextColumn get baseUnitId => text().references(UnitsTable, #id)();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// ProductUnitsTable defines conversion factors, barcodes, and pricing tiers for each unit.
/// Example: Carton of juice has conversionFactor = 24 relative to base unit (Piece).
@DataClassName('ProductUnitData')
class ProductUnitsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get productId => text().references(ProductsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get unitId => text().references(UnitsTable, #id)();
  
  /// Multiplier to convert this unit into the product's base unit (Piece = 1.0, Carton = 24.0)
  RealColumn get conversionFactor => real().withDefault(const Constant(1.0))(); 
  
  TextColumn get barcode => text().nullable().unique()();
  
  RealColumn get salePrice => real().withDefault(const Constant(0.0))();
  RealColumn get minSalePrice => real().withDefault(const Constant(0.0))();
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();

  BoolColumn get isDefaultSaleUnit => boolean().withDefault(const Constant(false))();
  BoolColumn get isDefaultPurchaseUnit => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// WarehousesTable defines physical storage locations, shelves, or store branches.
@DataClassName('WarehouseData')
class WarehousesTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get code => text().withLength(min: 1, max: 50).unique()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// InventoriesTable maintains the live stock balance and moving average cost snapshot
/// for each product inside a specific warehouse, measured exclusively in base units.
@DataClassName('InventoryData')
class InventoriesTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get warehouseId => text().references(WarehousesTable, #id)();
  TextColumn get productId => text().references(ProductsTable, #id)();
  
  /// Current quantity on hand in the product's base unit
  RealColumn get quantityOnHand => real().withDefault(const Constant(0.0))();
  
  /// Moving weighted average cost per base unit in base currency
  RealColumn get averageCost => real().withDefault(const Constant(0.0))();
  
  RealColumn get alertQuantity => real().withDefault(const Constant(5.0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {warehouseId, productId},
  ];
}

/// InventoryTransactionsTable provides a permanent, immutable audit ledger for every stock movement.
@DataClassName('InventoryTransactionData')
class InventoryTransactionsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get warehouseId => text().references(WarehousesTable, #id)();
  TextColumn get productId => text().references(ProductsTable, #id)();
  
  /// Movement type: 'In', 'Out', 'Adjustment', 'Damage', 'Transfer'
  TextColumn get transactionType => text()(); 
  
  /// Quantity in product's base unit
  RealColumn get quantity => real()();
  
  /// Base unit cost at the time of the transaction
  RealColumn get unitCost => real().withDefault(const Constant(0.0))();
  
  /// Reference type: 'SalesInvoice', 'PurchaseInvoice', 'StockTake', 'DamageVoucher', 'Transfer'
  TextColumn get referenceType => text()();
  TextColumn get referenceId => text()();
  
  DateTimeColumn get transactionDate => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
