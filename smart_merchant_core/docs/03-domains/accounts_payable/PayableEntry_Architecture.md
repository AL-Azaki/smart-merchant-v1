# PayableEntry Architecture

## 1. Purpose
The purpose of the `PayableEntry` entity is to provide a granular, immutable, and fully traceable ledger of every financial movement affecting a `SupplierPayable`. It is the singular mechanism through which a supplier's outstanding balance is modified, ensuring that every debit and credit is permanently recorded and auditable.

## 2. Responsibilities
- **Record Payable Movements:** Capturing the precise amount, direction (Debit/Credit), and date of every financial event impacting the business's debt to a supplier.
- **Increase Outstanding Balance:** Recording transactions (e.g., purchase invoices) that add to the amount owed by the business.
- **Decrease Outstanding Balance:** Recording transactions (e.g., outgoing payments) that reduce the amount owed by the business.
- **Record Purchase Invoice Creation:** Logging the exact financial impact of a finalized supplier bill against the payable account.
- **Record Payment Allocations:** Logging the exact financial impact of an outbound payment against the payable account.
- **Record Adjustments:** Safely applying non-transactional corrections (e.g., early payment discounts, late fee penalties) to the balance.
- **Record Write-offs:** Formally reducing the expected payable balance when debt is forgiven or deemed cleared without actual payment.

## 3. Entity Classification
- **Classification:** Child Entity
- **Domain:** Accounts Payable
- **Important:** It is strictly a Child Entity and NEVER an Aggregate Root. It has no independent existence outside the context of its parent `SupplierPayable`.

## 4. Relationships
- **SupplierPayable (Parent/Owner):** A mandatory, direct hierarchical relationship. Every `PayableEntry` must belong to exactly one `SupplierPayable`. Operations on entries are always routed through the parent.
- **Financial Document (Polymorphic Reference):** An optional, loosely coupled reference to any system-approved Financial Document (e.g., `PurchaseInvoice`, `Payment`, `CreditNote`) using the standard `document_type` / `document_id` polymorphic pattern.

## 5. Lifecycle
- The lifecycle of a `PayableEntry` is entirely bounded by and subordinate to its parent `SupplierPayable`.
- It cannot be created, modified, or deleted independently of its parent aggregate.
- Once created and committed, a `PayableEntry` enters an **immutable** state. Its financial values and core attributes can never be altered.

## 6. Business Rules
- Every `PayableEntry` MUST belong to exactly one `SupplierPayable`.
- Every entry must carry a non-zero positive amount, categorized strictly by a defined `direction` (Debit or Credit).
- Once committed to the database, entries are permanently immutable.
- Entries cannot be deleted (No Soft Deletes, No Hard Deletes).
- The `SupplierPayable`'s `outstanding_balance` is logically derived purely from the net sum of all its approved `PayableEntry` records.
- If an error must be corrected, a new compensatory `PayableEntry` (Adjustment or Reversal) must be created.

## 7. Entry Types Policy
`PayableEntry` must be classified by an `entry_type` that clearly defines the nature of the movement:
- **Invoice (Bill):** A credit entry resulting from a finalized purchase, increasing the business's debt to the supplier.
- **Payment:** A debit entry resulting from disbursed funds, decreasing the business's debt.
- **Credit Note:** A debit entry reducing the debt due to returns to the supplier, overcharges, or compensations.
- **Debit Note:** A credit entry increasing the debt due to undercharges or additional supplier fees.
- **Adjustment:** A manual or automated correction entry to handle discrepancies, rounding differences, or applied discounts.
- **Write-off:** A debit entry used to formally clear debt from the expected payable balance without payment.

## 8. Financial Document Policy
- A `PayableEntry` may reference any system-approved Financial Document without being tightly coupled to a specific domain's internal database tables.
- This is implemented using the standard `Financial Document Policy` (polymorphic tracking via `document_type` and `document_id`).
- This design ensures the Accounts Payable Domain remains completely agnostic to the internal database structures of the Purchasing, Banking, or Payments domains.

## 9. Currency Policy
- A `PayableEntry` operates strictly in the base currency of its parent `SupplierPayable`.
- The `amount` field always represents the base-currency impact on the aggregate's balance.
- If an entry originates from a foreign currency document (e.g., an international supplier bill), the following must be stored:
  - The original foreign currency amount.
  - The foreign currency code.
  - The exchange rate applied at the moment of entry creation.
- Currency conversion calculation logic is external to this entity.

## 10. Ownership Rules
- The `SupplierPayable` Aggregate Root is the sole and exclusive owner of the `PayableEntry`.
- All operations (Create, Read, Revert) on a `PayableEntry` must be routed through the `SupplierPayable`.
- It is architecturally prohibited to operate on a `PayableEntry` directly via a dedicated API, Controller, or Repository.

## 11. Audit Trail
- Every `PayableEntry` must record the `created_by` user identifier and the `created_at` timestamp at the exact moment of creation.
- Any compensatory entry (reversal) must ideally reference the original document or entry it is correcting to maintain a clear audit chain.

## 12. Immutability Rules
- `PayableEntry` is inherently and permanently immutable.
- `SoftDeletes` are strictly prohibited.
- Direct `UPDATE` operations on any financial or structural fields (`amount`, `entry_type`, `direction`, `created_at`) are strictly prohibited.
- Corrective actions must always generate a new `PayableEntry`, preserving the complete historical ledger.

## 13. Dependencies
- **SupplierPayable Architecture:** The parent Aggregate Root that governs the entry state and balance validity.
- **Financial Documents Foundation:** For the standard polymorphic document linking strategy.
- **Shared Value Objects Foundation:** For consistent monetary and currency value representations.

## 14. Out Of Scope
- **Payment Execution:** Processing or authorizing actual funds sent to the supplier.
- **Journal Entries:** Generating or posting General Ledger entries for expense realization, accounts payable liabilities, or payment clearing.
- **Bank Operations:** Interacting with bank accounts, feeds, or bank reconciliations.
- **Cash Operations:** Handling cash register movements or petty cash disbursements.
- **Purchase Approval Process:** The workflow for approving purchase orders or validating received goods.
- **Purchase Invoice Generation:** The internal representation of received supplier line items, taxes, and PDFs.
