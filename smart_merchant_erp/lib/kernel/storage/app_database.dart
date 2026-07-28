import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

// Foundation & Auth Tables
import 'tables/auth_tables.dart';

// Enums & Converters for Drift TypeConverters
import '../../database/enums/print_paper_size.dart';
import '../../database/converters/print_paper_size_converter.dart';
import '../../database/enums/sequence_reset_frequency.dart';
import '../../database/converters/sequence_reset_frequency_converter.dart';
import '../../database/enums/system_setting_type.dart';
import '../../database/converters/system_setting_type_converter.dart';
import '../../database/converters/json_converter.dart';
import '../../database/enums/inventory_movement_direction.dart';
import '../../database/converters/inventory_movement_direction_converter.dart';
import '../../database/enums/inventory_reference_type.dart';
import '../../database/converters/inventory_reference_type_converter.dart';
import '../../database/enums/inventory_transaction_status.dart';
import '../../database/converters/inventory_transaction_status_converter.dart';
import '../../database/enums/inventory_transaction_type.dart';
import '../../database/converters/inventory_transaction_type_converter.dart';
import '../../database/enums/inventory_transfer_status.dart';
import '../../database/converters/inventory_transfer_status_converter.dart';

// Domain 1: Core
import '../../database/tables/core/account_types_table.dart';
import '../../database/tables/core/branches_table.dart';
import '../../database/tables/core/businesses_table.dart';
import '../../database/tables/core/currencies_table.dart';
import '../../database/tables/core/print_settings_table.dart';
import '../../database/tables/core/sequences_table.dart';
import '../../database/tables/core/system_settings_table.dart';

// Domain 2: Catalog
import '../../database/tables/catalog/branch_product_prices_table.dart';
import '../../database/tables/catalog/brands_table.dart';
import '../../database/tables/catalog/categories_table.dart';
import '../../database/tables/catalog/product_images_table.dart';
import '../../database/tables/catalog/product_taxes_table.dart';
import '../../database/tables/catalog/product_units_table.dart';
import '../../database/tables/catalog/product_variants_table.dart';
import '../../database/tables/catalog/products_table.dart';
import '../../database/tables/catalog/taxes_table.dart';
import '../../database/tables/catalog/units_table.dart';

// Domain 3: Inventory
import '../../database/tables/inventory/inventories_table.dart';
import '../../database/tables/inventory/inventory_transaction_lines_table.dart';
import '../../database/tables/inventory/inventory_transactions_table.dart';
import '../../database/tables/inventory/inventory_transfer_items_table.dart';
import '../../database/tables/inventory/inventory_transfers_table.dart';
import '../../database/tables/inventory/warehouses_table.dart';

// Domain 4: Sales
import '../../database/tables/sales/channels_table.dart';
import '../../database/tables/sales/customer_receivables_table.dart';
import '../../database/tables/sales/customers_table.dart';
import '../../database/tables/sales/order_items_table.dart';
import '../../database/tables/sales/orders_table.dart';
import '../../database/tables/sales/receivable_entries_table.dart';
import '../../database/tables/sales/sales_invoice_items_table.dart';
import '../../database/tables/sales/sales_invoices_table.dart';
import '../../database/tables/sales/sales_return_items_table.dart';
import '../../database/tables/sales/sales_returns_table.dart';

// Domain 5: Purchasing
import '../../database/tables/purchasing/payable_entries_table.dart';
import '../../database/tables/purchasing/purchase_invoice_items_table.dart';
import '../../database/tables/purchasing/purchase_invoices_table.dart';
import '../../database/tables/purchasing/purchase_return_items_table.dart';
import '../../database/tables/purchasing/purchase_returns_table.dart';
import '../../database/tables/purchasing/supplier_payables_table.dart';
import '../../database/tables/purchasing/suppliers_table.dart';

// Domain 6: Accounting
import '../../database/tables/accounting/account_mappings_table.dart';
import '../../database/tables/accounting/accounting_periods_table.dart';
import '../../database/tables/accounting/chart_of_accounts_table.dart';
import '../../database/tables/accounting/fiscal_periods_table.dart';
import '../../database/tables/accounting/fiscal_years_table.dart';
import '../../database/tables/accounting/journal_entries_table.dart';
import '../../database/tables/accounting/journal_entry_lines_table.dart';
import '../../database/tables/accounting/opening_balances_table.dart';
import '../../database/tables/accounting/payment_terms_table.dart';

// Domain 7: Treasury
import '../../database/tables/treasury/bank_accounts_table.dart';
import '../../database/tables/treasury/bank_reconciliation_lines_table.dart';
import '../../database/tables/treasury/bank_reconciliations_table.dart';
import '../../database/tables/treasury/bank_transactions_table.dart';
import '../../database/tables/treasury/cash_registers_table.dart';
import '../../database/tables/treasury/cash_transactions_table.dart';
import '../../database/tables/treasury/payment_allocations_table.dart';
import '../../database/tables/treasury/payment_methods_table.dart';
import '../../database/tables/treasury/payments_table.dart';

// Domain 8: HR
import '../../database/tables/hr/departments_table.dart';
import '../../database/tables/hr/employee_documents_table.dart';
import '../../database/tables/hr/employees_table.dart';
import '../../database/tables/hr/job_titles_table.dart';

// Domain 9: Fixed Assets
import '../../database/tables/fixed_assets/depreciation_schedules_table.dart';
import '../../database/tables/fixed_assets/fixed_assets_table.dart';

// Domain 10: System Administration
import '../../database/tables/system/activity_logs_table.dart';
import '../../database/tables/system/attachments_table.dart';
import '../../database/tables/system/exchange_rates_table.dart';
import '../../database/tables/system/expense_categories_table.dart';
import '../../database/tables/system/expenses_table.dart';

part 'app_database.g.dart'; // This file will be generated by Drift

@lazySingleton
@DriftDatabase(
  tables: [
    // Foundation & Auth
    UsersTable,
    AccountsTable,
    SubscriptionsTable,

    // Domain 1: Core
    AccountTypes,
    Branches,
    Businesses,
    Currencies,
    PrintSettings,
    Sequences,
    SystemSettings,

    // Domain 2: Catalog
    BranchProductPrices,
    Brands,
    Categories,
    ProductImages,
    ProductTaxes,
    ProductUnits,
    ProductVariants,
    Products,
    Taxes,
    Units,

    // Domain 3: Inventory
    Inventories,
    InventoryTransactionLines,
    InventoryTransactions,
    InventoryTransferItems,
    InventoryTransfers,
    Warehouses,

    // Domain 4: Sales
    Channels,
    CustomerReceivables,
    Customers,
    OrderItems,
    Orders,
    ReceivableEntries,
    SalesInvoiceItems,
    SalesInvoices,
    SalesReturnItems,
    SalesReturns,

    // Domain 5: Purchasing
    PayableEntries,
    PurchaseInvoiceItems,
    PurchaseInvoices,
    PurchaseReturnItems,
    PurchaseReturns,
    SupplierPayables,
    Suppliers,

    // Domain 6: Accounting
    AccountMappings,
    AccountingPeriods,
    ChartOfAccounts,
    FiscalPeriods,
    FiscalYears,
    JournalEntries,
    JournalEntryLines,
    OpeningBalances,
    PaymentTerms,

    // Domain 7: Treasury
    BankAccounts,
    BankReconciliationLines,
    BankReconciliations,
    BankTransactions,
    CashRegisters,
    CashTransactions,
    PaymentAllocations,
    PaymentMethods,
    Payments,

    // Domain 8: HR
    Departments,
    EmployeeDocuments,
    Employees,
    JobTitles,

    // Domain 9: Fixed Assets
    DepreciationSchedules,
    FixedAssets,

    // Domain 10: System Administration
    ActivityLogs,
    Attachments,
    ExchangeRates,
    ExpenseCategories,
    Expenses,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? connection})
    : super(connection ?? _openConnection());

  @factoryMethod
  factory AppDatabase.injectable() => AppDatabase();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Seed default base currency 'YER' for offline-first usage
        await into(currencies).insert(
          CurrenciesCompanion.insert(
            id: 'YER',
            currencyCode: 'YER',
            currencyNameAr: 'ريال يمني',
            currencyNameEn: 'Yemeni Rial',
            currencySymbol: '﷼',
            isBaseCurrency: const Value(true),
            isActive: const Value(true),
          ),
        );
        
        // Seed SAR
        await into(currencies).insert(
          CurrenciesCompanion.insert(
            id: 'SAR',
            currencyCode: 'SAR',
            currencyNameAr: 'ريال سعودي',
            currencyNameEn: 'Saudi Riyal',
            currencySymbol: 'ر.س',
            isBaseCurrency: const Value(false),
            isActive: const Value(true),
          ),
        );

        // Seed USD
        await into(currencies).insert(
          CurrenciesCompanion.insert(
            id: 'USD',
            currencyCode: 'USD',
            currencyNameAr: 'دولار أمريكي',
            currencyNameEn: 'US Dollar',
            currencySymbol: '\$',
            isBaseCurrency: const Value(false),
            isActive: const Value(true),
          ),
        );
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
        
        // Clean up legacy QA seeder data that incorrectly used 'YER-id' instead of 'YER'
        // This prevents UNIQUE constraint failures on currencyCode when we auto-heal.
        await customStatement("DELETE FROM currencies WHERE currency_code = 'YER' AND id != 'YER';");
        
        // Ensure default base currency 'YER' is ALWAYS present for offline-first usage.
        // This is necessary if the DB was created before the onCreate seeder was added.
        await into(currencies).insertOnConflictUpdate(
          CurrenciesCompanion.insert(
            id: 'YER',
            currencyCode: 'YER',
            currencyNameAr: 'ريال يمني',
            currencyNameEn: 'Yemeni Rial',
            currencySymbol: '﷼',
            isBaseCurrency: const Value(true),
            isActive: const Value(true),
          ),
        );

        // Ensure SAR
        await into(currencies).insertOnConflictUpdate(
          CurrenciesCompanion.insert(
            id: 'SAR',
            currencyCode: 'SAR',
            currencyNameAr: 'ريال سعودي',
            currencyNameEn: 'Saudi Riyal',
            currencySymbol: 'ر.س',
            isBaseCurrency: const Value(false),
            isActive: const Value(true),
          ),
        );

        // Ensure USD
        await into(currencies).insertOnConflictUpdate(
          CurrenciesCompanion.insert(
            id: 'USD',
            currencyCode: 'USD',
            currencyNameAr: 'دولار أمريكي',
            currencyNameEn: 'US Dollar',
            currencySymbol: '\$',
            isBaseCurrency: const Value(false),
            isActive: const Value(true),
          ),
        );
      },
    );
  }
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
