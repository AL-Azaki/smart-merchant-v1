import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'accounting_tables.dart';

/// PaymentMethodsTable defines cash drawers, bank accounts, and payment options.
/// Each method links directly to a financial account in the Chart of Accounts.
@DataClassName('PaymentMethodData')
class PaymentMethodsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  /// Type: 'Cash', 'Bank', 'Network'
  TextColumn get type => text()(); 
  
  /// Linked asset account in chart_of_accounts (Cash drawer or Bank asset)
  TextColumn get accountId => text().references(ChartOfAccountsTable, #id)(); 
  
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
