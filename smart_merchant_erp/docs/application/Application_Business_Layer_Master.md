# APPLICATION / BUSINESS USE-CASE LAYER MASTER DOCUMENT
**Status**: COMPLETE
**Phase**: IMPLEMENTATION

## 1. Overview
The Application/Business Use-Case layer orchestrates operations across multiple domain repositories. It enforces business rules, ensures accounting integrity, and guarantees atomicity using the local-first SQLite database.

## 2. Core Infrastructure
- `ApplicationContext` (`lib/kernel/core/application_context.dart`): Abstracts multi-tenant contextual info (`businessId`, `branchId`, `userId`).
- `ApplicationTransactionRunner` (`lib/kernel/core/transaction_runner.dart`): Provides `runInTransaction` wrapping the Drift `AppDatabase.transaction` to ensure cross-repository atomic persistence.

## 3. Implemented Use Cases & Services
### Accounting & Financial Integrity
- **`AccountingApplicationService`**: Resolves `AccountMappings` (e.g., `accounts_receivable`, `sales_revenue`, `inventory_asset`) to actual `ChartOfAccounts` dynamically. Prevents hardcoded IDs.
- **`PostJournalEntryUseCase`**: Centralized logic for manual journal entries. Validates balance (Total Debit == Total Credit) and period locking before delegating to `AccountingRepository`.

### Sales & Receivables
- **`CompleteSaleUseCase`**: Orchestrates Sales, Inventory, and Accounting. 
  1. Validates stock availability using `InventoryRepository`.
  2. Resolves accounting maps.
  3. Prepares `SalesInvoices`, `SalesInvoiceItems`, and `CustomerReceivables`.
  4. Deducts stock via `InventoryTransactions` (Outbound).
  5. Posts Journal Entry (Debit AR/Cash & COGS, Credit Sales & Inventory).
  6. Executes all within `ApplicationTransactionRunner.runInTransaction`.

### Purchasing & Payables
- **`RecordPurchaseUseCase`**: Orchestrates Purchasing, Inventory, and Accounting.
  1. Validates purchase data.
  2. Resolves accounting maps.
  3. Prepares `PurchaseInvoices`, `PurchaseInvoiceItems`, and `SupplierPayables`.
  4. Adds stock via `InventoryTransactions` (Inbound).
  5. Posts Journal Entry (Debit Inventory, Credit AP/Cash).
  6. Executes atomically.

### Inventory Movement
- **`ProcessWarehouseTransferUseCase`**:
  1. Validates source stock.
  2. Prepares `InventoryTransfers`.
  3. Emits `transferOut` from source and `transferIn` to destination via `InventoryTransactions`.
  4. Persists atomically.

### Treasury & Payments
- **`ReceivePaymentUseCase`**: Orchestrates Treasury, Sales, and Accounting.
  1. Validates allocation amounts against `CustomerReceivables.remainingAmount`.
  2. Prepares `Payments` and `PaymentAllocations`.
  3. Submits `ReceivableEntries` to update paid/remaining balances.
  4. Closes Invoice/Receivable status if fully paid.
  5. Posts Journal Entry (Debit Cash, Credit AR).
  6. Executes atomically.

## 4. Design Guidelines
1. **No direct database access**: Use Cases must route all DB calls through Repository contracts (`SalesRepository`, `AccountingRepository`, etc.).
2. **Offline-First safety**: Companions are instantiated inside Use Cases, creating UUIDs on the spot. Sync logic handles eventual consistency.
3. **Strict Accounting**: Financial operations must never fail silently. Drift exceptions map to domain failures via `RepositoryErrorGuard`.

## 5. Testing & Accounting Audit
The Application Layer has successfully passed rigorous Transaction Auditing and Testing (`test/application/transaction_audit_test.dart`). 
Key verifications executed:
- **Transaction Atomicity**: Rollbacks have been actively proven. If journal posting fails (e.g., missing fiscal period), the entire transaction (Sales Invoice, Inventory Transaction, Receivable, and partial Journals) correctly rolls back, leaving no orphaned data.
- **Accounting Integrity**: All Journal Entries correctly enforce Double-Entry Accounting rules (Total Debit == Total Credit). 
- **Entity Resolution**: `AccountingApplicationService` effectively resolves Account Mappings (`accounts_receivable`, `sales_revenue`, etc.) directly from the live `ChartOfAccounts`.
- **Constraint Compliance**: Foreign key and check constraints (e.g., status enums like `'Unpaid'`) are respected from the Use Case layer down to the SQLite boundaries.

## 6. Formal Closure
The Final Verification, Accounting Audit, and Closure Gate for the Application / Business Use-Case Layer is officially **PASSED AND CLOSED**. 
The Smart Merchant ERP system possesses a complete, proven, and mathematically correct functional backend architecture (Schema -> DAO -> Repository -> Application Use-Cases) capable of executing localized transactions safely.
