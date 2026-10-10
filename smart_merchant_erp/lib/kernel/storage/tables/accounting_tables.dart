import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'currency_tables.dart';
import 'fiscal_tables.dart';

/// ChartOfAccountsTable defines the standard ledger accounts.
/// Accounts can be parent categories (allowPosting = false) or posting leaves (allowPosting = true).
/// System accounts (isSystem = true) cannot be renamed, reclassified, or deleted.
@DataClassName('AccountData')
class ChartOfAccountsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get parentId => text().nullable().references(ChartOfAccountsTable, #id)();
  TextColumn get accountCode => text().withLength(min: 1, max: 50).unique()();
  TextColumn get accountName => text().withLength(min: 1, max: 255)();
  
  /// Major account type: 'Asset', 'Liability', 'Equity', 'Revenue', 'Expense'
  TextColumn get accountType => text()(); 
  
  /// Normal balance orientation: 'Debit' or 'Credit'
  TextColumn get normalBalance => text()(); 
  
  /// Whether direct journal posting is allowed (false for parent headers)
  BoolColumn get allowPosting => boolean().withDefault(const Constant(true))();
  
  /// Protected system accounts essential for automated background engines
  BoolColumn get isSystem => boolean().withDefault(const Constant(true))();
  
  /// System role identifier (e.g. 'CASH_DRAWER_DEFAULT', 'SALES_REVENUE', 'COGS', 'INVENTORY_ASSET')
  TextColumn get systemRole => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// JournalEntriesTable records transaction headers for double-entry bookkeeping.
@DataClassName('JournalEntryData')
class JournalEntriesTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get fiscalYearId => text().references(FiscalYearsTable, #id)();
  TextColumn get entryNumber => text().withLength(min: 1, max: 50).unique()();
  DateTimeColumn get entryDate => dateTime().withDefault(currentDateAndTime)();
  
  /// Reference transaction type: 'SalesInvoice', 'PurchaseInvoice', 'Payment', 'Expense', 'StockAdjustment', 'Manual', 'ClosingEntry'
  TextColumn get referenceType => text()();
  TextColumn get referenceId => text().nullable()(); // UUID of invoice or voucher
  
  TextColumn get currencyId => text().references(CurrenciesTable, #id)();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();
  
  TextColumn get description => text().nullable()();
  
  /// Status: 'Posted', 'Voided'
  TextColumn get status => text().withDefault(const Constant('Posted'))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// JournalEntryLinesTable records the individual debit and credit legs of a journal entry.
/// Crucial: baseDebit and baseCredit store the converted amount in Base Currency,
/// ensuring that the ledger balance is always calculated and audited in a single, stable base currency.
@DataClassName('JournalEntryLineData')
class JournalEntryLinesTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get journalEntryId => text().references(JournalEntriesTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get lineNumber => integer()();
  TextColumn get accountId => text().references(ChartOfAccountsTable, #id)();
  
  TextColumn get description => text().nullable()();
  
  // Transaction currency amounts
  RealColumn get debit => real().withDefault(const Constant(0.0))();
  RealColumn get credit => real().withDefault(const Constant(0.0))();
  
  // Converted base currency amounts (Used for all balance sheets, trial balances & audits)
  RealColumn get baseDebit => real().withDefault(const Constant(0.0))();
  RealColumn get baseCredit => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}
