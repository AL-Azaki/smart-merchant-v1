import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'currency_tables.dart';
import 'party_tables.dart';
import 'payment_method_tables.dart';
import 'inventory_tables.dart';

/// Legacy CustomersTable kept for backward compatibility with existing auth migrations
@DataClassName('CustomerModel')
class CustomersTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get businessId => text()();
  TextColumn get customerName => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable().withLength(max: 30)();
  TextColumn get email => text().nullable().withLength(max: 255)();
  TextColumn get address => text().nullable()();
  RealColumn get creditLimit => real().withDefault(const Constant(0.00))();
  TextColumn get defaultCurrencyId => text().nullable()();
  RealColumn get openingBalance => real().withDefault(const Constant(0.00))();
  TextColumn get openingBalanceType => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SalesInvoicesTable records sales and sales-return invoice headers.
@DataClassName('SalesInvoiceData')
class SalesInvoicesTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get invoiceNumber => text().withLength(min: 1, max: 50).unique()();
  DateTimeColumn get invoiceDate => dateTime().withDefault(currentDateAndTime)();
  
  /// Customer ID (nullable for walk-in cash customers)
  TextColumn get customerId => text().nullable().references(PartiesTable, #id)();
  TextColumn get warehouseId => text().references(WarehousesTable, #id)();
  
  TextColumn get currencyId => text().references(CurrenciesTable, #id)();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  // Transaction currency totals
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountTotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxTotal => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0.0))();
  
  // Payment split
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0.0))();

  // Converted totals in base currency for accounting
  RealColumn get baseGrandTotal => real().withDefault(const Constant(0.0))();
  RealColumn get totalCogs => real().withDefault(const Constant(0.0))(); // Total Cost of Goods Sold

  // Statuses
  TextColumn get paymentStatus => text().withDefault(const Constant('Paid'))(); // 'Paid', 'Partial', 'Unpaid'
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))(); // 'Cash', 'Credit', 'Split'
  TextColumn get paymentMethodId => text().nullable().references(PaymentMethodsTable, #id)();

  TextColumn get invoiceType => text().withDefault(const Constant('Standard'))(); // 'Standard', 'Return'
  TextColumn get originalInvoiceId => text().nullable()();

  TextColumn get status => text().withDefault(const Constant('Posted'))(); // 'Posted', 'Voided'
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// SalesInvoiceItemsTable records line items with pricing, discounts, and inventory costs.
@DataClassName('SalesInvoiceItemData')
class SalesInvoiceItemsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get invoiceId => text().references(SalesInvoicesTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get lineNumber => integer()();
  
  TextColumn get productId => text().references(ProductsTable, #id)();
  TextColumn get productUnitId => text().references(ProductUnitsTable, #id)();
  
  RealColumn get quantity => real()();
  RealColumn get conversionFactor => real().withDefault(const Constant(1.0))();
  RealColumn get quantityBase => real()(); // quantity * conversionFactor

  RealColumn get unitPrice => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()(); // Net line amount
  
  RealColumn get unitCost => real().withDefault(const Constant(0.0))(); // Cost of base unit at checkout time
  RealColumn get lineCogs => real().withDefault(const Constant(0.0))(); // quantityBase * unitCost

  @override
  Set<Column> get primaryKey => {id};
}
