import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'accounting_tables.dart';

/// PartiesTable stores both customers and suppliers in a unified ledger-linked model.
/// Each party is assigned a designated sub-account in the Chart of Accounts upon creation.
@DataClassName('PartyData')
class PartiesTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  
  /// Party type: 'Customer', 'Supplier', 'Both'
  TextColumn get partyType => text()(); 
  
  TextColumn get phone => text().nullable().withLength(max: 50)();
  TextColumn get email => text().nullable().withLength(max: 255)();
  TextColumn get address => text().nullable()();
  
  /// Linked ledger account in chart_of_accounts
  TextColumn get accountId => text().references(ChartOfAccountsTable, #id)();
  
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))();
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  
  /// Opening balance direction: 'Debit' (owes us) or 'Credit' (we owe them)
  TextColumn get openingBalanceType => text().nullable()(); 
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
