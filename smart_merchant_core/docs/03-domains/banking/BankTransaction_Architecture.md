# BankTransaction Architecture

## 1. Purpose
The purpose of the `BankTransaction` entity is to provide a granular, immutable, and fully traceable record of every financial movement affecting a `BankAccount`. It is the singular mechanism through which a `BankAccount`'s balance is modified, and it serves as the permanent audit trail for every credit and debit operation within the Banking Domain.

## 2. Responsibilities
- **Transaction Recording:** Capturing the precise amount, direction (credit/debit), and timestamp of every bank movement.
- **Balance Impact:** Being the sole mechanism that drives an increase or decrease in the parent `BankAccount`'s `current_balance`.
- **Transfer Entry Recording:** Representing one side (debit or credit) of an internal `BankTransfer` operation.
- **Reconciliation Alignment:** Being the unit of data that is matched against official bank statement lines during a `BankReconciliation` session.
- **Adjustment Recording:** Capturing reconciliation adjustments (bank fees, interest, errors) as distinct, traceable entries.
- **Document Linking:** Associating the bank movement with its originating `Financial Document` when applicable, using the standard polymorphic pattern.

## 3. Entity Classification
- **Classification:** Child Entity
- **Domain:** Banking
- **Important:** It is strictly a Child Entity and NEVER an Aggregate Root. It has no independent existence outside the context of its parent `BankAccount`.

## 4. Relationships
- **BankAccount (Parent/Owner):** A mandatory, direct hierarchical relationship. Every `BankTransaction` must belong to exactly one `BankAccount`. Operations on transactions are always routed through the parent.
- **Financial Document (Polymorphic Reference):** An optional, loosely coupled reference to any system-approved Financial Document (e.g., `Payment`, `PurchaseInvoice`, `ManualJournal`) using the standard `document_type` / `document_id` polymorphic pattern. This keeps the Banking Domain agnostic of other domains' internals.
- **BankTransfer (Sibling Reference):** An optional reference linking this transaction to its originating `BankTransfer` aggregate, used to trace the two sides of an internal transfer.
- **User (Creator):** A reference to the user or system process that created the transaction for audit purposes.

## 5. Lifecycle
- The lifecycle of a `BankTransaction` is entirely bounded by and subordinate to its parent `BankAccount`.
- It cannot be created, modified, or deleted independently of its parent aggregate.
- Once created and committed, a `BankTransaction` enters an **immutable** state and its financial values cannot be altered.
- If an error must be corrected, a new compensatory `BankTransaction` (Adjustment or Reversal) is created; the original record is never touched.

## 6. Business Rules
- A `BankTransaction` MUST belong to exactly one `BankAccount`.
- A `BankTransaction` cannot be created against a `BankAccount` in a `Closed` state.
- A `BankTransaction` of type `Debit` cannot be created against a `BankAccount` in a `Frozen` state.
- Every `BankTransaction` must carry a non-zero positive amount.
- Once committed, the amount, date, and direction of a `BankTransaction` are immutable.
- Every `BankTransaction` must impact the parent `BankAccount`'s `current_balance` within the same database transaction (atomically).
- A `BankTransaction` must record the exact exchange rate used if it involves a foreign currency amount.

## 7. Transaction Types Policy
`BankTransaction` must be classified by a `transaction_type` that clearly defines the nature and direction of the movement:
- **Deposit:** An inflow of funds from an external source (e.g., customer cash deposit, opening balance).
- **Withdrawal:** An outflow of funds to an external destination (e.g., vendor payment, cash withdrawal).
- **Transfer In:** A credit entry resulting from a `BankTransfer` sent from another internal bank account.
- **Transfer Out:** A debit entry resulting from a `BankTransfer` sent to another internal bank account.
- **Adjustment:** A manual correction entry used during reconciliation to account for discrepancies (e.g., bank fees, interest, errors not yet in the system).
- **Bank Fee:** A specific debit representing charges levied by the banking institution.
- **Interest:** A specific credit representing interest earned on the account balance.

## 8. Financial Document Policy
- A `BankTransaction` may optionally reference any system-approved Financial Document without being tightly coupled to a specific domain's table.
- This is implemented using the standard `Financial Document Policy` (polymorphic tracking via `document_type` and `document_id`).
- This design ensures the Banking Domain remains agnostic to the internal structures of the Sales, Purchasing, and Payments Domains.
- Not all `BankTransaction` records require a linked document (e.g., bank fee adjustments may be standalone).

## 9. Currency Policy
- A `BankTransaction` operates strictly in the base currency of its parent `BankAccount`.
- The `amount` field always represents the base-currency impact on the account balance.
- If a transaction originates from a foreign currency source, the following must be stored:
  - The original foreign currency amount.
  - The foreign currency code.
  - The exchange rate applied at the moment of the transaction.
  - The calculated base-currency equivalent (stored in `amount`).
- Currency conversion logic is external to this entity and must be resolved before the `BankTransaction` is created.

## 10. Ownership Rules
- The `BankAccount` is the sole and exclusive owner of the `BankTransaction`.
- All operations (Create, Read, Revert) on a `BankTransaction` must be routed through the `BankAccount` Aggregate Root.
- It is architecturally prohibited to operate on a `BankTransaction` directly, bypassing its parent `BankAccount`.

## 11. Audit Trail
- Every `BankTransaction` must record the `created_by` user identifier and the `created_at` timestamp at the moment of creation.
- Any compensatory reversal transaction must reference the `id` of the original transaction it is nullifying, creating a traceable chain.
- The `reconciliation_status` of each transaction (e.g., Unreconciled, Reconciled) must be tracked to support the reconciliation process.

## 12. Immutability Rules
- `BankTransaction` is inherently and permanently immutable.
- `SoftDeletes` are strictly prohibited.
- Direct `UPDATE` operations on financial fields (`amount`, `transaction_type`, `created_at`) are strictly prohibited.
- Corrective actions must always generate a new, compensatory `BankTransaction` entry, preserving the complete audit history.

## 13. Dependencies
- **BankAccount Architecture:** The parent Aggregate Root that governs the account state and session validity.
- **Financial Documents Foundation:** For the standard polymorphic document linking strategy.
- **Shared Value Objects Foundation:** For consistent monetary and currency value representations.
- **BankTransfer Architecture:** For understanding the two-sided entry relationship in fund transfers.

## 14. Out Of Scope
- **Journal Entry Creation:** Generating General Ledger postings is the exclusive responsibility of the Finance Domain's Posting Engine.
- **Payment Processing:** Settling invoices or managing Accounts Receivable/Payable belongs to the Payments Domain.
- **Cash Register Operations:** Any movement of physical cash belongs to the Cash Management Domain.
- **External Banking APIs:** Fetching transactions directly from bank feeds is outside this domain's responsibility.
- **Online Banking Connectivity:** Real-time bank feeds (Open Banking) are not managed here.
- **Currency Conversion Calculation:** Live exchange rate fetching and calculation is external to this entity.
