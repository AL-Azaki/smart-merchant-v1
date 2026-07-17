# ReceivableEntry Architecture

## 1. Purpose
The purpose of the `ReceivableEntry` entity is to provide a granular, immutable, and fully traceable ledger of every financial movement affecting a `CustomerReceivable`. It is the singular mechanism through which a customer's outstanding balance is modified, ensuring that every debit and credit is permanently recorded and auditable.

## 2. Responsibilities
- **Record Receivable Movements:** Capturing the precise amount, direction (Debit/Credit), and date of every financial event impacting the customer's debt.
- **Increase Outstanding Balance:** Recording transactions (e.g., invoices) that add to the amount owed by the customer.
- **Decrease Outstanding Balance:** Recording transactions (e.g., payments) that reduce the amount owed by the customer.
- **Record Invoice Creation:** Logging the exact financial impact of a finalized sales invoice against the receivable account.
- **Record Payment Allocations:** Logging the exact financial impact of a received payment against the receivable account.
- **Record Adjustments:** Safely applying non-transactional corrections (e.g., early payment discounts, late fees) to the balance.
- **Record Write-offs:** Formally reducing the expected receivable balance when debt is deemed uncollectible.

## 3. Entity Classification
- **Classification:** Child Entity
- **Domain:** Accounts Receivable
- **Important:** It is strictly a Child Entity and NEVER an Aggregate Root. It has no independent existence outside the context of its parent `CustomerReceivable`.

## 4. Relationships
- **CustomerReceivable (Parent/Owner):** A mandatory, direct hierarchical relationship. Every `ReceivableEntry` must belong to exactly one `CustomerReceivable`. Operations on entries are always routed through the parent.
- **Financial Document (Polymorphic Reference):** An optional, loosely coupled reference to any system-approved Financial Document (e.g., `SalesInvoice`, `Payment`, `CreditNote`) using the standard `document_type` / `document_id` polymorphic pattern.

## 5. Lifecycle
- The lifecycle of a `ReceivableEntry` is entirely bounded by and subordinate to its parent `CustomerReceivable`.
- It cannot be created, modified, or deleted independently of its parent aggregate.
- Once created and committed, a `ReceivableEntry` enters an **immutable** state. Its financial values and core attributes can never be altered.

## 6. Business Rules
- Every `ReceivableEntry` MUST belong to exactly one `CustomerReceivable`.
- Every entry must carry a non-zero positive amount, categorized strictly by a defined `direction` (Debit or Credit).
- Once committed to the database, entries are permanently immutable.
- Entries cannot be deleted (No Soft Deletes, No Hard Deletes).
- The `CustomerReceivable`'s `outstanding_balance` is logically derived purely from the net sum of all its approved `ReceivableEntry` records.
- If an error must be corrected, a new compensatory `ReceivableEntry` (Adjustment or Reversal) must be created.

## 7. Entry Types Policy
`ReceivableEntry` must be classified by an `entry_type` that clearly defines the nature of the movement:
- **Invoice:** A debit entry resulting from a finalized sale, increasing the customer's debt.
- **Payment:** A credit entry resulting from received funds, decreasing the customer's debt.
- **Credit Note:** A credit entry reducing the debt due to returns, overcharges, or compensations.
- **Debit Note:** A debit entry increasing the debt due to undercharges or additional fees.
- **Adjustment:** A manual or automated correction entry to handle discrepancies, rounding differences, or applied discounts.
- **Write-off:** A credit entry used to formally clear uncollectible debt from the expected receivable balance.

## 8. Financial Document Policy
- A `ReceivableEntry` may reference any system-approved Financial Document without being tightly coupled to a specific domain's table.
- This is implemented using the standard `Financial Document Policy` (polymorphic tracking via `document_type` and `document_id`).
- This design ensures the Accounts Receivable Domain remains completely agnostic to the internal database structures of the Sales, Purchasing, Banking, or Payments domains.

## 9. Currency Policy
- A `ReceivableEntry` operates strictly in the base currency of its parent `CustomerReceivable`.
- The `amount` field always represents the base-currency impact on the aggregate's balance.
- If an entry originates from a foreign currency document, the following must be stored:
  - The original foreign currency amount.
  - The foreign currency code.
  - The exchange rate applied at the moment of entry creation.
- Currency conversion calculation logic is external to this entity.

## 10. Ownership Rules
- The `CustomerReceivable` Aggregate Root is the sole and exclusive owner of the `ReceivableEntry`.
- All operations (Create, Read, Revert) on a `ReceivableEntry` must be routed through the `CustomerReceivable`.
- It is architecturally prohibited to operate on a `ReceivableEntry` directly via a dedicated API, Controller, or Repository.

## 11. Audit Trail
- Every `ReceivableEntry` must record the `created_by` user identifier and the `created_at` timestamp at the exact moment of creation.
- Any compensatory entry (reversal) must ideally reference the original document or entry it is correcting to maintain a clear audit chain.

## 12. Immutability Rules
- `ReceivableEntry` is inherently and permanently immutable.
- `SoftDeletes` are strictly prohibited.
- Direct `UPDATE` operations on any financial or structural fields (`amount`, `entry_type`, `direction`, `created_at`) are strictly prohibited.
- Corrective actions must always generate a new `ReceivableEntry`, preserving the complete historical ledger.

## 13. Dependencies
- **CustomerReceivable Architecture:** The parent Aggregate Root that governs the entry state and balance validity.
- **Financial Documents Foundation:** For the standard polymorphic document linking strategy.
- **Shared Value Objects Foundation:** For consistent monetary and currency value representations.

## 14. Out Of Scope
- **Payment Execution:** Processing or authorizing actual funds from the customer.
- **Journal Entries:** Generating or posting General Ledger entries for revenue, bad debt, or AR asset accounts.
- **Bank Operations:** Interacting with bank accounts, feeds, or bank reconciliations.
- **Cash Operations:** Handling cash register movements or cash drawer balances.
- **Credit Approval Process:** The workflow for determining a customer's creditworthiness.
- **Invoice Generation:** The creation of sale line items, tax calculations, and invoice PDFs.
