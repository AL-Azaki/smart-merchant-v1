import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Customers Table
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
  TextColumn get openingBalanceType => text().nullable()(); // 'debit' or 'credit'
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sales Invoices Table
@DataClassName('SalesInvoiceModel')
class SalesInvoicesTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get businessId => text()();
  TextColumn get branchId => text()();
  TextColumn get customerId => text().nullable()();

  TextColumn get invoiceNumber => text().withLength(min: 1, max: 50)();
  DateTimeColumn get invoiceDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime().nullable()();

  TextColumn get currencyId => text()();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.00000000))();

  // Currency Totals
  RealColumn get subTotal => real().withDefault(const Constant(0.00))();
  RealColumn get discountTotal => real().withDefault(const Constant(0.00))();
  RealColumn get taxTotal => real().withDefault(const Constant(0.00))();
  RealColumn get grandTotal => real().withDefault(const Constant(0.00))();

  // Base Currency Totals (For reporting)
  RealColumn get baseSubtotal => real().withDefault(const Constant(0.00))();
  RealColumn get baseDiscountTotal => real().withDefault(const Constant(0.00))();
  RealColumn get baseTaxTotal => real().withDefault(const Constant(0.00))();
  RealColumn get baseGrandTotal => real().withDefault(const Constant(0.00))();

  // Statuses
  TextColumn get paymentStatus => text().withDefault(const Constant('Unpaid'))(); // Unpaid, Partial, Paid
  TextColumn get status => text().withDefault(const Constant('Draft'))(); // Draft, Posted, Cancelled
  
  TextColumn get notes => text().nullable()();
  TextColumn get createdBy => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  // ⚠️ CRITICAL OFFLINE-FIRST BUG FIX:
  // In the original SQL, the unique constraint was just (business_id, invoice_number).
  // This causes a crash if two offline devices in different branches generate 'INV-001' at the same time.
  // The fix: The unique constraint MUST include the branch_id.
  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, branchId, invoiceNumber}, // Fixed constraint
  ];
}
