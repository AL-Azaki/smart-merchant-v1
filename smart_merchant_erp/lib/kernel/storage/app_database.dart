import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'tables/auth_tables.dart';
import 'tables/sales_tables.dart';
import 'tables/currency_tables.dart';
import 'tables/fiscal_tables.dart';
import 'tables/accounting_tables.dart';
import 'tables/party_tables.dart';
import 'tables/payment_method_tables.dart';
import 'tables/inventory_tables.dart';

part 'app_database.g.dart';

@lazySingleton
@DriftDatabase(tables: [
  // Auth & Multi-tenant
  UsersTable,
  AccountsTable,
  SubscriptionsTable,

  // Legacy/Draft
  CustomersTable,
  SalesInvoicesTable,

  // Phase 1 Core Financial Engine
  CurrenciesTable,
  FiscalYearsTable,
  ChartOfAccountsTable,
  JournalEntriesTable,
  JournalEntryLinesTable,
  PartiesTable,
  PaymentMethodsTable,

  // Phase 2 Catalog & Inventory Engine
  UnitsTable,
  ProductsTable,
  ProductUnitsTable,
  WarehousesTable,
  InventoriesTable,
  InventoryTransactionsTable,
])
class AppDatabase extends _$AppDatabase {
  /// Default production constructor with optional connection for testing
  AppDatabase({QueryExecutor? connection}) : super(connection ?? _openConnection());

  /// Named constructor specifically for testing
  AppDatabase.forTesting(QueryExecutor connection) : super(connection);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'smart_merchant_erp_local.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
