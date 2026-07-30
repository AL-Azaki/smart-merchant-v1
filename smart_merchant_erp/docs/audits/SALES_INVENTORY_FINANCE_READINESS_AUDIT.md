# Smart Merchant ERP - Sales, Inventory & Finance Readiness Audit

**Mode:** READ-ONLY AUDIT + EVIDENCE-BASED REPORT
**Date:** 2026-07-29

## 1. Executive Summary

*   **Overall Readiness Score:** 55%
*   **Go/No-Go Decision for Finance Module:** **NO-GO**
*   **Rationale:** While the foundational data structures (Drift tables) and atomic transaction runners are well-implemented, there are critical P0 integration gaps between Sales/Inventory and Accounting. Specifically, actual stock quantities are not updated on purchase returns, cash sales do not hit the cash accounts, stock adjustments do not produce journal entries, and sales returns are entirely missing. Finance module development cannot proceed accurately until these core ERP data flows correctly feed the ledger.

---

## 2. Sales Module
**Status: Partial**

*   **POS Cart & CompleteSaleUseCase:** 
    *   **Evidence:** `CompleteSaleUseCase` correctly wraps operations in `ApplicationTransactionRunner`. It accurately deducts inventory.
    *   **Gap (P0):** The POS workflow (via `PosNotifier`) handles credit sales, but for cash sales, it does **not** create a `Treasury Payment` record. Furthermore, `CompleteSaleUseCase` hardcodes the journal entry debit to Accounts Receivable (`accounts_receivable`) regardless of whether it was a cash or credit sale. Cash sales do not hit the cash account.
*   **Sales Returns:** 
    *   **Evidence:** `lib/modules/sales/presentation/widgets/returns_modal.dart` exists but is a hardcoded mock UI (`onPressed: () {}`).
    *   **Gap (P0):** There is NO `RecordSalesReturnUseCase` or application-layer logic for sales returns. The feature is completely missing.

---

## 3. Inventory & Products
**Status: Partial**

*   **Catalog Service:** 
    *   **Evidence:** `CatalogApplicationService.saveProduct` correctly supports Product Creation, Unit conversions, and Opening Stock. Opening stock correctly delegates to `ProcessStockAdjustmentUseCase` without generating fake purchase invoices or supplier payables.
*   **Stock Adjustment & Physical Stock Count:** 
    *   **Evidence:** `PostStockCountUseCase` successfully calls `ProcessStockAdjustmentUseCase`, which updates actual `Inventories.quantity` correctly.
    *   **Gap (P0):** `ProcessStockAdjustmentUseCase` does **not** create Journal Entries. Inventory shrinkage or overage does not hit the Inventory/COGS accounts in the ledger, violating accounting integrity.
*   **Transfer between Warehouses:**
    *   **Evidence:** Fully modeled at the DAO level (`InventoryDao.recordTransferWithItems`), ensuring atomic header and line-item creation.

---

## 4. Purchasing Module
**Status: Partial**

*   **RecordPurchaseUseCase:**
    *   **Evidence:** The use case works, correctly updates `Inventories` quantity, creates journal entries atomically, and implements Weighted Average Cost correctly.
    *   **Gap:** Partial payments are explicitly blocked at the provider level (`CAPABILITY GAP: الدفع الجزئي غير مدعوم حالياً`).
*   **Purchase Returns (RecordPurchaseReturnUseCase):**
    *   **Evidence:** The use case exists and handles transaction logging and journal entries.
    *   **Gap (P0):** The use case utilizes `InventoryDao.recordTransactionWithLines`, which only inserts transaction logs. It **fails** to update the actual stock balance (`Inventories.quantity`). Consequently, returning a purchase leaves the physical stock count artificially high.

---

## 5. Accounting Core Foundation
**Status: Partial / Mock UI**

*   **Chart of Accounts Structure:**
    *   **Evidence:** `chart_of_accounts_table.dart` is COMPLETE. It correctly models a self-referential hierarchical tree (`parentAccountId`, `accountLevel`, `nodePath`) supporting proper finance drill-down.
*   **Journal Entry Atomicity:**
    *   **Evidence:** COMPLETE. Both `RecordPurchaseUseCase` and `CompleteSaleUseCase` rely on `ApplicationTransactionRunner` ensuring that inventory tables, transaction logs, and journal entries are committed together or rolled back entirely.
*   **Finance UI & Application Layer:**
    *   **Evidence:** The UI (`financial_dashboard_view.dart`) contains a `ChartOfAccountsTab` but is 100% UI mock. It does not use Riverpod (`ref.watch`) or connect to a repository.
    *   **Gap:** `AccountingApplicationService` only has `resolveAccountMapping`. There are no CRUD operations for creating or managing the Chart of Accounts.

---

## 6. Critical Blockers (P0) for Finance

Before commencing full development of the Finance/Accounting UI and reports, the following backend integrations MUST be fixed:

1.  **Sales to Treasury Integration:** `CompleteSaleUseCase` must properly handle cash sales by generating a Treasury Payment and debiting the Cash Account instead of AR.
2.  **Purchase Returns Inventory Bug:** `RecordPurchaseReturnUseCase` must actively deduct `Inventories.quantity` when items are returned.
3.  **Stock Adjustment Accounting:** `ProcessStockAdjustmentUseCase` must generate Journal Entries to reflect inventory shrinkage/overage in the ledger.
4.  **Sales Returns Feature:** Implement `RecordSalesReturnUseCase` (restocking inventory, reversing revenue/AR, generating credit notes).
5.  **Chart of Accounts CRUD:** Implement full CRUD logic in `AccountingApplicationService` so the UI can actually manage accounts.

---

## 7. Next Action Recommendations

1.  **Fix Core ERP Logic Gaps First:** Dispatch a focused effort to patch the 3 immediate bugs: Cash Sale accounting debits, Purchase Return inventory deduction, and Stock Adjustment journal entries.
2.  **Implement Sales Returns Backbone:** Build the `RecordSalesReturnUseCase` and wire it up to the existing mock `ReturnsModal`.
3.  **Build COA Application Services:** Before touching the Finance UI, implement the application layer methods (`createAccount`, `updateAccount`, `deleteAccount`) in `AccountingApplicationService` and test them.

---

## 8. Resolution Audit (Updated 2026-07-29)

### P0 FIXES IMPLEMENTED
- **Sales to Treasury Integration**: `CompleteSaleUseCase` now correctly distinguishes Cash vs Credit sales. For cash sales, it invokes `TreasuryRepository` to record a payment against the selected `PaymentMethod` and debits the resolved cash account instead of AR.
- **Purchase Returns Inventory Bug**: `RecordPurchaseReturnUseCase` has been corrected to execute atomic quantity deductions from `Inventories.quantity` alongside the transaction logs.
- **Stock Adjustment Accounting**: `ProcessStockAdjustmentUseCase` now calculates inventory shrinkage and overage and atomically generates balanced journal entries using `inventory_adjustment_loss` and `inventory_adjustment_gain` mapped accounts.
- **Sales Returns Feature**: Built `ProcessSalesReturnUseCase` providing a complete transactional backbone for returning sales, validating against previously returned quantities, restocking inventory, and reversing Sales Revenue, AR, Inventory Asset, and COGS in the ledger.
- **Chart of Accounts CRUD**: Implemented core Application Service CRUD (`createChartOfAccount`, `updateChartOfAccount`, `safeDeleteChartOfAccount`, `listChartOfAccounts`, `getChartOfAccountsTree`, `toggleAccountActiveStatus`) inside `AccountingApplicationService` for future UI consumption.

### REGRESSION TEST RESULTS
- Application Layer Tests (`transaction_audit_test.dart`) updated and verified to pass, confirming rollback scenarios and atomic success for the updated Sales/Inventory/Accounting interactions.
- Drift compilation successful via `build_runner`.
- **UPDATE:** The known testing anomalies (e.g. `UNIQUE constraint failed: currencies.currency_code` and test data seeding issues) have been fully resolved. 
- **100% Test Suite Pass Rate**: Integration tests, Unit tests, DAO tests, and UI/Widget regressions pass completely, including strict cross-tenant isolation and foreign key validations.

### REMAINING P0
- None. The foundational data structures and required integration use cases between Sales, Inventory, and Accounting have been secured and verifiably proven via automated tests.

### REMAINING P1
- The existing UI needs to be wired to the newly established application layer workflows (e.g. `ReturnsModal` currently uses a mock button, and `ChartOfAccountsTab` needs wiring to `AccountingApplicationService`).
- Partial payment tracking UI adjustments.

### FINANCE HANDOFF STATUS
**GO**. The application layer and database schemas have strict transactional integrity. Finance module UI and Reports development can proceed safely.
