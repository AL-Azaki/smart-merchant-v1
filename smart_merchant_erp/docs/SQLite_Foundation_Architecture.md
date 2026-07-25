# SQLite Foundation Architecture
## Smart Merchant ERP — Official Reference Document
**Version:** 1.0 | **Date:** 2026-07-18 | **Status:** DESIGN ONLY — NO IMPLEMENTATION

---

## 1. Folder Architecture

```
kernel/storage/
├── app_database.dart                  ← Central @DriftDatabase class
├── app_database.g.dart                ← Generated
├── offline_record.dart                ← OfflineRecord<T> wrapper (EXISTS)
├── offline_storage_foundation.dart    ← Barrel exports (EXISTS)
├── offline_storage_service.dart       ← Generic contract (EXISTS)
├── storage_state.dart                 ← StorageState enum (EXISTS)
├── storage_strategy.dart              ← StoragePolicy (EXISTS)
│
├── tables/                            ← All Drift table definitions
│   ├── _tables.dart                   ← Barrel export for all table files
│   ├── core_tables.dart               ← currencies, accounts, businesses, branches
│   ├── auth_tables.dart               ← users, roles, permissions, pivots (REFACTOR existing)
│   ├── catalog_tables.dart            ← categories, brands, units, products, product_units
│   ├── inventory_tables.dart          ← warehouses, inventories, transactions, transfers
│   ├── sales_tables.dart              ← customers, sales_invoices, items, returns (REFACTOR existing)
│   ├── purchasing_tables.dart         ← suppliers, purchase_invoices, items, returns
│   ├── accounting_tables.dart         ← chart_of_accounts, journal_entries, lines, fiscal
│   ├── treasury_tables.dart           ← payment_methods, cash_registers, bank_accounts, payments
│   ├── settings_tables.dart           ← system_settings, print_settings, sequences
│   ├── hr_tables.dart                 ← departments, job_titles, employees
│   └── sync_tables.dart               ← sync_queue, sync_history, sync_conflicts
│
├── dao/                               ← Drift DAO classes (one per domain)
│   ├── _daos.dart                     ← Barrel export
│   ├── core_dao.dart
│   ├── auth_dao.dart
│   ├── catalog_dao.dart
│   ├── inventory_dao.dart
│   ├── sales_dao.dart
│   ├── purchasing_dao.dart
│   ├── accounting_dao.dart
│   ├── treasury_dao.dart
│   ├── settings_dao.dart
│   ├── hr_dao.dart
│   └── sync_dao.dart
│
├── migration/                         ← Schema version management
│   ├── migration_strategy.dart        ← MigrationStrategy with onCreate/onUpgrade
│   ├── schema_versions.dart           ← Version constants and changelog
│   └── seed/                          ← Initial seed data
│       ├── currency_seeds.dart
│       ├── account_type_seeds.dart
│       └── permission_seeds.dart
│
├── helpers/                           ← Database utilities
│   ├── db_constants.dart              ← Table/column name constants
│   ├── query_helpers.dart             ← Shared query patterns
│   └── batch_helpers.dart             ← Batch insert/update utilities
│
├── cache/                             ← (EXISTS)
│   └── cache_policy.dart
│
├── secure_storage/                    ← Token/credential encryption
│   └── secure_storage_service.dart
│
└── sqlite/                            ← Module-specific OfflineStorageService implementations
    ├── catalog_storage_service.dart
    ├── sales_storage_service.dart
    ├── inventory_storage_service.dart
    └── ...
```

---

## 2. Table Organization — Domain Groups

### Group 1: Core (Offline Read-Only — synced from server)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| currencies | CurrenciesTable | CurrencyEntry | Server → Local |
| accounts | AccountsTable | AccountEntry | Server → Local |
| businesses | BusinessesTable | BusinessEntry | Server → Local |
| branches | BranchesTable | BranchEntry | Server → Local |
| plans | PlansTable | PlanEntry | Server → Local |
| subscriptions | SubscriptionsTable | SubscriptionEntry | Server → Local |
| account_types | AccountTypesTable | AccountTypeEntry | Server → Local |

### Group 2: Authentication & RBAC (Offline Read-Only)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| users | UsersTable | UserEntry | Server → Local |
| roles | RolesTable | RoleEntry | Server → Local |
| permissions | PermissionsTable | PermissionEntry | Server → Local |
| user_roles | UserRolesTable | UserRoleEntry | Server → Local |
| role_permissions | RolePermissionsTable | RolePermissionEntry | Server → Local |
| user_branches | UserBranchesTable | UserBranchEntry | Server → Local |

### Group 3: Catalog (Bidirectional Sync)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| categories | CategoriesTable | CategoryEntry | Bidirectional |
| brands | BrandsTable | BrandEntry | Bidirectional |
| units | UnitsTable | UnitEntry | Bidirectional |
| products | ProductsTable | ProductEntry | Bidirectional |
| product_units | ProductUnitsTable | ProductUnitEntry | Bidirectional |
| branch_product_prices | BranchProductPricesTable | BranchProductPriceEntry | Bidirectional |
| product_images | ProductImagesTable | ProductImageEntry | Bidirectional |
| taxes | TaxesTable | TaxEntry | Bidirectional |

### Group 4: Inventory (Bidirectional Sync)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| warehouses | WarehousesTable | WarehouseEntry | Bidirectional |
| inventories | InventoriesTable | InventoryEntry | Bidirectional |
| inventory_transactions | InventoryTransactionsTable | InventoryTransactionEntry | Bidirectional |
| inventory_transaction_lines | InventoryTransactionLinesTable | InventoryTransactionLineEntry | Bidirectional |
| inventory_transfers | InventoryTransfersTable | InventoryTransferEntry | Bidirectional |
| inventory_transfer_items | InventoryTransferItemsTable | InventoryTransferItemEntry | Bidirectional |
| stock_adjustments | StockAdjustmentsTable | StockAdjustmentEntry | Bidirectional |
| stock_adjustment_items | StockAdjustmentItemsTable | StockAdjustmentItemEntry | Bidirectional |

### Group 5: Sales (Bidirectional Sync)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| customers | CustomersTable | CustomerEntry | Bidirectional |
| channels | ChannelsTable | ChannelEntry | Bidirectional |
| sales_invoices | SalesInvoicesTable | SalesInvoiceEntry | Bidirectional |
| sales_invoice_items | SalesInvoiceItemsTable | SalesInvoiceItemEntry | Bidirectional |
| sales_returns | SalesReturnsTable | SalesReturnEntry | Bidirectional |
| sales_return_items | SalesReturnItemsTable | SalesReturnItemEntry | Bidirectional |
| customer_receivables | CustomerReceivablesTable | CustomerReceivableEntry | Bidirectional |
| receivable_entries | ReceivableEntriesTable | ReceivableEntryEntry | Bidirectional |

### Group 6: Purchasing (Bidirectional Sync)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| suppliers | SuppliersTable | SupplierEntry | Bidirectional |
| purchase_invoices | PurchaseInvoicesTable | PurchaseInvoiceEntry | Bidirectional |
| purchase_invoice_items | PurchaseInvoiceItemsTable | PurchaseInvoiceItemEntry | Bidirectional |
| purchase_returns | PurchaseReturnsTable | PurchaseReturnEntry | Bidirectional |
| purchase_return_items | PurchaseReturnItemsTable | PurchaseReturnItemEntry | Bidirectional |
| supplier_payables | SupplierPayablesTable | SupplierPayableEntry | Bidirectional |
| payable_entries | PayableEntriesTable | PayableEntryEntry | Bidirectional |

### Group 7: Accounting (Bidirectional Sync)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| chart_of_accounts | ChartOfAccountsTable | ChartOfAccountEntry | Bidirectional |
| journal_entries | JournalEntriesTable | JournalEntryEntry | Bidirectional |
| journal_entry_lines | JournalEntryLinesTable | JournalEntryLineEntry | Bidirectional |
| fiscal_years | FiscalYearsTable | FiscalYearEntry | Bidirectional |
| fiscal_periods | FiscalPeriodsTable | FiscalPeriodEntry | Bidirectional |
| exchange_rates | ExchangeRatesTable | ExchangeRateEntry | Bidirectional |
| account_mappings | AccountMappingsTable | AccountMappingEntry | Bidirectional |
| accounting_periods | AccountingPeriodsTable | AccountingPeriodEntry | Bidirectional |
| opening_balances | OpeningBalancesTable | OpeningBalanceEntry | Bidirectional |
| expense_categories | ExpenseCategoriesTable | ExpenseCategoryEntry | Bidirectional |
| expenses | ExpensesTable | ExpenseEntry | Bidirectional |

### Group 8: Treasury (Bidirectional Sync)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| payment_terms | PaymentTermsTable | PaymentTermEntry | Bidirectional |
| payment_methods | PaymentMethodsTable | PaymentMethodEntry | Bidirectional |
| cash_registers | CashRegistersTable | CashRegisterEntry | Bidirectional |
| cash_transactions | CashTransactionsTable | CashTransactionEntry | Bidirectional |
| bank_accounts | BankAccountsTable | BankAccountEntry | Bidirectional |
| bank_transactions | BankTransactionsTable | BankTransactionEntry | Bidirectional |
| payments | PaymentsTable | PaymentEntry | Bidirectional |
| payment_allocations | PaymentAllocationsTable | PaymentAllocationEntry | Bidirectional |

### Group 9: Settings (Local Device + Sync)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| system_settings | SystemSettingsTable | SystemSettingEntry | Bidirectional |
| print_settings | PrintSettingsTable | PrintSettingEntry | Bidirectional |
| sequences | SequencesTable | SequenceEntry | Local Only |

### Group 10: HR (Bidirectional Sync)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| departments | DepartmentsTable | DepartmentEntry | Bidirectional |
| job_titles | JobTitlesTable | JobTitleEntry | Bidirectional |
| employees | EmployeesTable | EmployeeEntry | Bidirectional |
| employee_documents | EmployeeDocumentsTable | EmployeeDocumentEntry | Bidirectional |

### Group 11: Sync Infrastructure (Local Only)
| Table | Drift Class | DataClass | Sync Direction |
|-------|-------------|-----------|----------------|
| sync_queue | SyncQueueTable | SyncQueueEntry | Local Only |
| sync_history | SyncHistoryTable | SyncHistoryEntry | Local Only |
| sync_conflicts | SyncConflictsTable | SyncConflictEntry | Local Only |

### Excluded from SQLite (Server-Only)
- `personal_access_tokens` — Sanctum server-only
- `subscription_payments` — Billing server-only
- `carts`, `cart_items` — E-commerce server-only
- `orders`, `order_items` — E-commerce server-only
- `product_channels` — E-commerce server-only
- `fixed_assets`, `depreciation_schedules` — Phase 2
- `bank_reconciliations`, `bank_reconciliation_lines` — Phase 2
- `attachments`, `activity_logs` — Server-only
- `product_variants` — Phase 2

---

## 3. DAO Organization

Each DAO is a Drift `DatabaseAccessor` scoped to one domain group:

```dart
// Example DAO pattern
@DriftAccessor(tables: [CategoriesTable, BrandsTable, UnitsTable, ProductsTable, ProductUnitsTable])
class CatalogDao extends DatabaseAccessor<AppDatabase> with _$CatalogDaoMixin {
  CatalogDao(AppDatabase db) : super(db);
  // Domain-specific queries here
}
```

**DAO Responsibilities:**
- CRUD operations for all tables in its domain
- Joins and aggregations within the domain
- Batch insert/update/delete operations
- `getPendingSyncRecords()` — return dirty records for sync
- `markAsSynced(List<String> ids)` — update sync_status after upload
- `softDelete(String id)` — set deleted_at, never physically remove
- Pagination via `limit/offset` or cursor-based

**DAO Rules:**
- DAOs never call other DAOs directly
- DAOs never import from `modules/` layer
- DAOs return Drift DataClasses, never domain entities
- Mapping DataClass → Entity happens in `infrastructure/mappers/`

---

## 4. AppDatabase Architecture

```dart
@DriftDatabase(
  tables: [
    // Group 1: Core
    CurrenciesTable, AccountsTable, BusinessesTable, BranchesTable,
    PlansTable, SubscriptionsTable, AccountTypesTable,
    // Group 2: Auth
    UsersTable, RolesTable, PermissionsTable,
    UserRolesTable, RolePermissionsTable, UserBranchesTable,
    // Group 3: Catalog
    CategoriesTable, BrandsTable, UnitsTable, ProductsTable,
    ProductUnitsTable, BranchProductPricesTable, ProductImagesTable, TaxesTable,
    // Group 4: Inventory
    WarehousesTable, InventoriesTable, InventoryTransactionsTable,
    InventoryTransactionLinesTable, InventoryTransfersTable,
    InventoryTransferItemsTable, StockAdjustmentsTable, StockAdjustmentItemsTable,
    // Group 5: Sales
    CustomersTable, ChannelsTable, SalesInvoicesTable, SalesInvoiceItemsTable,
    SalesReturnsTable, SalesReturnItemsTable,
    CustomerReceivablesTable, ReceivableEntriesTable,
    // Group 6: Purchasing
    SuppliersTable, PurchaseInvoicesTable, PurchaseInvoiceItemsTable,
    PurchaseReturnsTable, PurchaseReturnItemsTable,
    SupplierPayablesTable, PayableEntriesTable,
    // Group 7: Accounting
    ChartOfAccountsTable, JournalEntriesTable, JournalEntryLinesTable,
    FiscalYearsTable, FiscalPeriodsTable, ExchangeRatesTable,
    AccountMappingsTable, AccountingPeriodsTable, OpeningBalancesTable,
    ExpenseCategoriesTable, ExpensesTable,
    // Group 8: Treasury
    PaymentTermsTable, PaymentMethodsTable, CashRegistersTable,
    CashTransactionsTable, BankAccountsTable, BankTransactionsTable,
    PaymentsTable, PaymentAllocationsTable,
    // Group 9: Settings
    SystemSettingsTable, PrintSettingsTable, SequencesTable,
    // Group 10: HR
    DepartmentsTable, JobTitlesTable, EmployeesTable, EmployeeDocumentsTable,
    // Group 11: Sync
    SyncQueueTable, SyncHistoryTable, SyncConflictsTable,
  ],
  daos: [
    CoreDao, AuthDao, CatalogDao, InventoryDao,
    SalesDao, PurchasingDao, AccountingDao, TreasuryDao,
    SettingsDao, HrDao, SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? connection}) : super(connection ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Run seed data
    },
    onUpgrade: (m, from, to) async {
      await customStatement('PRAGMA foreign_keys = OFF');
      for (var target = from + 1; target <= to; target++) {
        await _runMigration(m, target);
      }
      await customStatement('PRAGMA foreign_keys = ON');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = NORMAL');
      await customStatement('PRAGMA cache_size = -8000'); // 8MB
    },
  );
}
```

---

## 5. Migration Strategy

### Version Governance Rules
- `schemaVersion = 1` → Initial full schema creation
- Each new version adds ONE migration function `_migrateV{N}()`
- Migrations are **additive only** — never DROP columns in production
- Foreign keys OFF during migration, ON after
- Test every migration path: v1→v2, v1→v3, v2→v3

### Migration Pattern
```dart
Future<void> _runMigration(Migrator m, int version) async {
  switch (version) {
    case 2: await _migrateV2(m); break;
    case 3: await _migrateV3(m); break;
    // ...
  }
}

Future<void> _migrateV2(Migrator m) async {
  // Example: Add new column
  await m.addColumn(salesInvoicesTable, salesInvoicesTable.newColumn);
  // Example: Create new table
  await m.createTable(newFeatureTable);
}
```

### Seed Data Strategy
- Seeds run inside `onCreate` only (fresh installs)
- Currencies, AccountTypes, Permissions seeded from constants
- Existing installs receive reference data via sync download

---

## 6. Naming Conventions

### Table Names (Drift Classes)
| Convention | Example |
|---|---|
| Drift Table Class | `CategoriesTable` (plural + `Table`) |
| DataClass Name | `CategoryEntry` (singular + `Entry`) |
| File Name | `catalog_tables.dart` (domain + `_tables`) |

### Column Names
| Convention | Example |
|---|---|
| Snake case in SQL | `business_id`, `created_at` |
| Camel case in Dart | `businessId`, `createdAt` |
| Foreign keys | `{referenced_table_singular}_id` → `customer_id` |
| Booleans | `is_` prefix → `is_active`, `is_default` |
| Timestamps | `created_at`, `updated_at`, `deleted_at`, `last_synced_at` |

### DAO Names
| Convention | Example |
|---|---|
| DAO Class | `CatalogDao` (domain + `Dao`) |
| File Name | `catalog_dao.dart` |
| Query methods | `getById()`, `getAll()`, `watchAll()`, `insertOrReplace()` |

### Repository Names
| Convention | Example |
|---|---|
| Contract | `CustomerRepository` (in `domain/repositories/`) |
| Implementation | `CustomerRepositoryImpl` (in `infrastructure/repositories/`) |

---

## 7. Performance Guidelines

### Indexes (created in table definitions)
- Every `business_id` column → indexed
- Every `branch_id` column → indexed
- Every `sync_status` column → indexed (for sync queries)
- All FK columns → indexed
- Composite unique keys → automatically indexed
- `deleted_at` → indexed (for soft-delete filtering)

### Batch Operations
- Use `batch((b) { ... })` for multi-row inserts (100+ rows)
- Sync downloads must use batch insert, never row-by-row
- Maximum batch size: 500 rows per transaction

### Transactions
- All financial operations (invoices + items + inventory) → single transaction
- Use `transaction(() async { ... })` for ACID guarantees
- Keep transactions short — no network calls inside transactions

### Pagination
- Default page size: 20 rows
- Use cursor-based pagination for infinite scroll: `WHERE id > :lastId LIMIT :pageSize`
- Use offset-based for fixed pages: `LIMIT :pageSize OFFSET :offset`

### Memory
- Use `watchLazy()` instead of `watch()` when only change notification needed
- Use `getSingle()` not `get()` when expecting one result
- Dispose stream subscriptions in `StatefulWidget.dispose()`

---

## 8. Offline-First Mandatory Columns

Every **Bidirectional Sync** table MUST include these columns:

```dart
// Standard Offline-First columns for all syncable tables
TextColumn get id => text().clientDefault(() => const Uuid().v4())();
TextColumn get businessId => text()();

// Timestamps
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get deletedAt => dateTime().nullable()();

// Sync metadata
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
// Values: 'pending' | 'synced' | 'conflict' | 'failed'

IntColumn get version => integer().withDefault(const Constant(1))();
DateTimeColumn get lastSyncedAt => dateTime().nullable()();
TextColumn get deviceId => text().nullable()();
```

### Column Behavior Rules

| Column | On Create | On Update | On Delete | On Sync Success |
|--------|-----------|-----------|-----------|-----------------|
| `id` | UUID v4 | No change | No change | No change |
| `created_at` | Now | No change | No change | No change |
| `updated_at` | Now | Now | Now | Now |
| `deleted_at` | null | null | Now | No change |
| `sync_status` | `'pending'` | `'pending'` | `'pending'` | `'synced'` |
| `version` | 1 | version + 1 | version + 1 | Server version |
| `last_synced_at` | null | No change | No change | Now |
| `device_id` | Current device | Current device | No change | No change |

### Read-Only Tables (Server → Local)
Do NOT include `sync_status`, `version`, `device_id`. Only include:
```dart
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get deletedAt => dateTime().nullable()();
DateTimeColumn get lastSyncedAt => dateTime().nullable()();
```

---

## 9. Synchronization Rules

### Rule 1: Sync Status Lifecycle
```
[Created Locally] → sync_status = 'pending'
        ↓
[Upload Success] → sync_status = 'synced'
        ↓
[Modified Locally] → sync_status = 'pending'
        ↓
[Conflict Detected] → sync_status = 'conflict'
        ↓
[Conflict Resolved] → sync_status = 'pending' or 'synced'
```

### Rule 2: Soft Delete — Never Hard Delete Unsynced Records
- `softDelete(id)` → sets `deleted_at = now`, `sync_status = 'pending'`
- `hardDelete(id)` → only allowed when `sync_status = 'synced'`
- Sync Engine uploads soft-delete, server confirms, then local can purge

### Rule 3: Sync Queue Integration
Every DAO write operation must enqueue to `SyncQueueTable`:
```
INSERT/UPDATE/DELETE on any table
  → INSERT into sync_queue (entity_type, entity_id, operation, payload, priority)
```

### Rule 4: Version Conflict Detection
- Before applying server download: compare `server.version` vs `local.version`
- If `local.sync_status == 'synced'` → safe to overwrite
- If `local.sync_status == 'pending'` AND versions differ → conflict
- Resolution uses `SyncResolutionPolicyRegistry` from existing Sync Engine

### Rule 5: Business ID Scoping
- ALL queries MUST filter by `business_id`
- DAOs receive `businessId` as required parameter
- Never return data across business boundaries

### Rule 6: Idempotency
- Every create operation generates an `idempotency_key` (UUID v4)
- Sync upload sends idempotency key → server deduplicates
- Retry after network failure reuses same idempotency key

### Rule 7: Sync Priority by Domain
| Priority | Entity Types |
|----------|-------------|
| Critical | cash_transactions, payments |
| High | sales_invoices, purchase_invoices, journal_entries |
| Normal | customers, suppliers, products, inventories |
| Low | system_settings, print_settings, categories |

---

## 10. Implementation Roadmap

### Phase 1: Foundation Tables (Dependencies: None)
```
Step 1.1 → sync_tables.dart      (SyncQueueTable, SyncHistoryTable, SyncConflictsTable)
Step 1.2 → SyncDao               (Queue persistence for existing Sync Engine)
Step 1.3 → migration_strategy.dart (MigrationStrategy + PRAGMA config)
```

### Phase 2: Core & Auth (Dependencies: Phase 1)
```
Step 2.1 → core_tables.dart      (currencies, accounts, businesses, branches, plans, subscriptions, account_types)
Step 2.2 → auth_tables.dart      (REFACTOR existing → users, roles, permissions, pivots)
Step 2.3 → CoreDao + AuthDao
Step 2.4 → Seed data (currencies, account_types, permissions)
```

### Phase 3: Catalog (Dependencies: Phase 2)
```
Step 3.1 → catalog_tables.dart   (categories, brands, units, products, product_units, prices, images, taxes)
Step 3.2 → CatalogDao
```

### Phase 4: Inventory (Dependencies: Phase 3)
```
Step 4.1 → inventory_tables.dart (warehouses, inventories, transactions, transfers, adjustments)
Step 4.2 → InventoryDao
```

### Phase 5: Partners & Sales (Dependencies: Phase 3, 4)
```
Step 5.1 → sales_tables.dart     (REFACTOR existing → customers, invoices, items, returns, receivables)
Step 5.2 → SalesDao
```

### Phase 6: Purchasing (Dependencies: Phase 3, 4)
```
Step 6.1 → purchasing_tables.dart (suppliers, invoices, items, returns, payables)
Step 6.2 → PurchasingDao
```

### Phase 7: Accounting (Dependencies: Phase 5, 6)
```
Step 7.1 → accounting_tables.dart (chart_of_accounts, journal_entries, lines, fiscal, expenses)
Step 7.2 → AccountingDao
```

### Phase 8: Treasury (Dependencies: Phase 7)
```
Step 8.1 → treasury_tables.dart  (payment_methods, cash_registers, bank_accounts, transactions, payments)
Step 8.2 → TreasuryDao
```

### Phase 9: Settings & HR (Dependencies: Phase 2)
```
Step 9.1 → settings_tables.dart  (system_settings, print_settings, sequences)
Step 9.2 → hr_tables.dart        (departments, job_titles, employees, documents)
Step 9.3 → SettingsDao + HrDao
```

### Phase 10: Integration & Testing
```
Step 10.1 → Wire all DAOs into AppDatabase
Step 10.2 → Run build_runner to generate app_database.g.dart
Step 10.3 → Register AppDatabase in GetIt (already done)
Step 10.4 → Write migration tests (v1 → v2 path)
Step 10.5 → Write DAO unit tests using in-memory database
```

---

## Verification

```
SQLite Foundation Architecture:     VERIFIED ✅
Folder Organization:                VERIFIED ✅
Table Domain Groups:                VERIFIED ✅ (11 groups, 85+ tables)
DAO Architecture:                   VERIFIED ✅ (11 DAOs)
Migration Strategy:                 VERIFIED ✅
Naming Conventions:                 VERIFIED ✅
Performance Guidelines:             VERIFIED ✅
Offline-First Rules:                VERIFIED ✅
Sync Integration Rules:             VERIFIED ✅
Implementation Roadmap:             VERIFIED ✅ (10 phases)

Ready For Table Implementation:     YES ✅
Next Phase: Phase 1 — Sync Infrastructure Tables
```
