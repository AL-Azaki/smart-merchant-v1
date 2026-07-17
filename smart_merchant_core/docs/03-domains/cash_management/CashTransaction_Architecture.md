# CashTransaction Architecture

## 1. Purpose
The purpose of the `CashTransaction` entity is to provide an immutable and traceable record of any financial movement (inflow or outflow) that affects the balance of a `CashRegister`. It serves as the granular building block for the financial integrity of the cash management system.

## 2. Responsibilities
- **Movement Recording:** Recording the exact amount of cash added to or removed from the cash box.
- **Balance Impact:** Triggering an increase or decrease in the parent `CashRegister`'s current balance.
- **Justification:** Documenting the business reason or origin of the cash movement.
- **Document Linking:** Associating the cash movement with a corresponding official `Financial Document` (e.g., Payment Receipt, Expense Voucher) when applicable.

## 3. Entity Classification
- **Classification:** Child Entity
- **Domain:** Cash Management
- **Note:** It is strictly a Child Entity and NEVER an Aggregate Root.

## 4. Relationships
- **CashRegister (Parent):** A mandatory direct hierarchical relationship. The `CashRegister` owns the transaction.
- **Financial Document (Polymorphic Reference):** An optional, loosely coupled reference to any valid official document across the system (e.g., `Payment`, `PurchaseInvoice`) that initiated the transaction, utilizing standard `document_type` and `document_id` patterns.
- **User:** A reference to the operator or system user who performed the transaction.

## 5. Lifecycle
- The lifecycle of a `CashTransaction` is entirely bounded by its parent `CashRegister`.
- It cannot be created, processed, or exist independently.
- Once created and attached to an `Open` register session, its state is final.

## 6. Business Rules
- A `CashTransaction` MUST belong to exactly one valid `CashRegister`.
- A `CashTransaction` cannot be executed if the parent `CashRegister` is `Closed`.
- Every `CashTransaction` must have a non-zero financial value that mathematically impacts the register's balance.
- Once a transaction is committed, it cannot be individually hard-deleted or altered. Corrections require a compensatory `CashTransaction`.

## 7. Transaction Types Policy
`CashTransaction` classifications must clearly define the direction and nature of the cash flow:
- **Deposit:** Cash added from an external source (e.g., Owner injection).
- **Withdrawal:** Cash removed to an external destination (e.g., Bank deposit).
- **Transfer In:** Cash received internally from another register or box.
- **Transfer Out:** Cash sent internally to another register or box.
- **Adjustment:** A manual correction made during closing (Overage/Shortage).
- **Payment / Receipt:** Cash flow resulting directly from standard business operations (Sales/Purchases).

## 8. Financial Document Policy
- A `CashTransaction` can link to any system-approved Financial Document without tightly coupling to its specific database table.
- This is achieved using the standard `Financial Document Policy` (polymorphic tracking via `document_type` and `document_id`).
- This ensures the Cash Management domain remains agnostic to the internal workings of the Sales, Purchasing, or Payments domains.

## 9. Currency Policy
- The `CashTransaction` strictly adheres to the base currency of its parent `CashRegister`.
- Currency conversions (e.g., receiving USD in a SAR register) MUST be handled prior to creating the `CashTransaction`. The transaction itself only records the equivalent value in the register's base currency.
- No direct multi-currency calculations are performed within this Child Entity.

## 10. Ownership Rules
- The `CashRegister` is the sole owner of the `CashTransaction`.
- All operations (Create, Read, Revert) concerning a `CashTransaction` must be routed through the `CashRegister` Aggregate Root.

## 11. Audit Trail
- Each transaction must record the `created_by` user identifier.
- The precise `created_at` timestamp is mandatory to establish the chronological sequence of cash movements.
- Any compensatory transaction (Reversal) must clearly reference the ID of the original transaction it is nullifying.

## 12. Immutability Rules
- The `CashTransaction` is inherently immutable.
- `SoftDeletes` or `Updates` to financial values are strictly prohibited.
- If a mistake occurs, the transaction remains in the database, and a new "Reversal" transaction is created to offset the balance mathematically.

## 13. Dependencies
- **CashRegister Architecture:** The parent Aggregate Root defining session state.
- **Financial Documents Foundation:** For the standard polymorphic linking strategy.
- **Shared Value Objects Foundation:** For consistent currency and monetary value representations.

## 14. Out Of Scope
- **Bank Transactions:** Movements affecting bank accounts.
- **Accounting Posting:** Generating Journal Entries directly (this is handled by Finance Domain integration).
- **Currency Conversion:** Fetching or calculating live exchange rates.
- **Payment Gateway Processing:** Interacting with external digital payment providers.
- **External Wallets:** Apple Pay, STC Pay balances.
