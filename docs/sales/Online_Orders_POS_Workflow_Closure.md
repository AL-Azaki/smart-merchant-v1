# Online Orders → Cashier Review → POS Handoff
## Implementation Closure Document

**Date:** 2026-07-25
**Module:** Sales & E-Commerce Integration
**Database:** SQLite (Local Offline-First)

---

### 1. Architectural Invariants Enforced
During this implementation, we strictly enforced the following non-negotiable rules:
- **No Side Effects on Arrival:** When `SyncCoordinator` pulls an online order from the backend and calls `SalesDao.insertOnlineOrder`, it **ONLY** inserts into the `orders` and `order_items` tables. It explicitly does **NOT** touch `sales_invoices`, `inventory_transactions`, or `journal_entries`. 
- **Explicit Cashier Review:** All new orders arrive in the local `Pending` state. The cashier must manually review them in the `OrdersListView` (Orders Inbox).
- **Acceptance ≠ Sale:** Accepting an order merely transitions its status from `Pending` to `Confirmed`. It confirms to the customer that the order is being processed, but it still does NOT deduct stock, capture payment, or generate accounting entries.
- **POS Source of Truth:** To finalize a sale, the cashier must hit "Open in POS" (Handoff). This transfers the `OrderItems` into the POS Cart while retaining the explicit `unitPrice` set by the storefront. The cashier uses the standard checkout flow to tender payment.
- **Atomic Sales Execution:** Only when the cashier clicks "Complete Sale" does the `CompleteSaleUseCase` execute. This guarantees that stock is accurately checked at the time of physical packing, payment is collected, and financial ledgers are balanced.
- **Duplicate Protection:** The `sourceOrderId` is passed through the `PosState`. A check ensures an order cannot be loaded into the POS if it has already been fulfilled (`Delivered`).

### 2. Components Implemented

#### Database & DAOs
- `SalesDao`: Verified and hardened `insertOnlineOrder` (UPSERT with idempotency), `updateOrderStatus`, `listOnlineOrders`, and `getOrderWithItemsById`.
- *Note: Tenant scoping (`business_id`) is strictly enforced on all queries.*

#### Application Services
- `OnlineOrderService`: Built application layer to handle `acceptOrder`, `rejectOrder`, and `markOrderFulfilled`. Guards were added to prevent invalid state transitions (e.g., cannot accept a deleted order, cannot fulfill a non-confirmed order).

#### State Management (Riverpod)
- `OnlineOrdersNotifier`: A reactive stream provider connected directly to `SalesDao.watchOrders`, meaning the UI auto-updates the moment a background sync pulls new data.
- `OnlineOrdersActionNotifier`: Handles stateful actions (Accept, Reject, Filter by Status, Search).
- `PosNotifier`: Extended with `sourceOrderId` tracking and `loadFromOnlineOrder(OrderWithItems)` to map remote order structures into the local POS `PosCartItem` model.

#### Presentation Layer (UI)
- `OrdersListView`: Replaced the placeholder with a full, production-ready Inbox view.
- Added status filter chips with counter badges (Pending, Confirmed, Cancelled, Delivered).
- Added a search bar for order numbers.
- Built `_OrderDetailsSheet` for the cashier to review order items, notes, and totals before taking action.
- `SalesLayout`: Refactored to use an `InheritedWidget` (`SalesTabScope`) to allow programmatic navigation from the Orders tab (index 2) directly to the POS tab (index 0) upon handoff.

### 3. Price Policy & Taxes
When an order is handed off to the POS, the `unitPrice` from the `OrderItem` is mapped directly to the POS Cart. The system explicitly bypasses dynamic pricing/discounts in the POS at this step because the customer already agreed to the storefront price at checkout.

### 4. Verification & Tests
A comprehensive test suite was written and executed (`test/unit/modules/sales/application/online_order_workflow_test.dart`):
- `insertOnlineOrder persists order and items to SQLite`
- `online order pull creates ZERO sales invoices/inventory/journal entries`
- `accepting order changes status but creates no invoice`
- `rejecting order preserves the original record`
- `Business A cannot see Business B orders`
- `order marked as Delivered cannot be re-confirmed`

**All 11 tests pass successfully against an in-memory Drift SQLite instance.**

### 5. Conclusion
The POS is now safely integrated with the E-Commerce flow. The architecture successfully isolates external noise from internal accounting and inventory ledgers until a human cashier explicitly signs off on the transaction.
