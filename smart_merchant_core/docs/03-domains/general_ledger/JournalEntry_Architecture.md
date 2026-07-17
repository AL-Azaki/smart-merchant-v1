# JournalEntry Architecture

## 1. Purpose
The purpose of the `JournalEntry` Aggregate Root is to represent a single, authoritative, double-entry accounting transaction within the General Ledger. It acts as the immutable container that guarantees the mathematical balance and historical integrity of financial movements across the business's Chart of Accounts.

## 2. Responsibilities
- **Own the Accounting Transaction:** Serve as the primary record for any financial event impacting the general ledger.
- **Control Posting Lifecycle:** Manage the transition of a transaction from Draft to Posted, enforcing validation rules at each step.
- **Guarantee Balanced Entries:** Enforce the fundamental accounting equation by ensuring total debits equal total credits before allowing a post.
- **Own all Journal Entry Lines:** Act as the exclusive parent and gatekeeper for all individual account impact lines (debits and credits).
- **Support Reversals:** Provide a standardized mechanism for correcting errors by linking original entries to mathematically opposite compensating entries.
- **Preserve Immutable Accounting History:** Ensure that once posted, financial data is permanently locked and protected against unauthorized or silent modification.

## 3. Entity Classification
- **Classification:** Aggregate Root
- **Domain:** General Ledger (GL)

## 4. Relationships
- **Business:** Scopes the journal entry to a specific tenant.
- **Branch:** Optional scoping to a specific physical or logical branch.
- **Fiscal Period:** The accounting period into which this entry is recorded.
- **Currency:** The primary base currency of the transaction.
- **Posting User:** The authenticated user or system process that executed the post operation.

## 5. Lifecycle
The `JournalEntry` aggregate adheres to the following states:
- **Draft:** The entry and its lines are being constructed. It is not yet validated for balance, and it has no impact on ledger account balances.
- **Posted:** The entry is mathematically balanced, validated against the fiscal period, and permanently locked. Its financial impact is officially recorded in the ledger.
- **Reversed:** A previously posted entry that has been logically negated by a subsequent, linked compensating `JournalEntry`.

## 6. Business Rules
- **Every Journal Entry must balance:** `Sum of Debits` must exactly equal `Sum of Credits`.
- **A posted entry cannot be edited:** No modifications to lines, amounts, dates, or accounts are permitted after posting.
- **Reversal creates a new Journal Entry:** Correcting an error requires generating a new `JournalEntry` with opposite signs (or swapped debit/credit logic) that references the original entry.
- **JournalEntry owns all JournalEntryLines:** Lines cannot exist, be modified, or be evaluated independently of their parent aggregate.
- **Tenant Isolation:** A journal entry cannot span multiple businesses.
- **Fiscal Period Enforcement:** An entry cannot be posted into a closed fiscal period.

## 7. Posting Policy
- Posting is a strict, atomic, one-way state transition.
- The posting operation MUST validate the mathematical balance of the aggregate's lines.
- The posting operation MUST verify that the associated Fiscal Period is "Open".
- The posting operation MUST record the timestamp and the identity of the user/process requesting the post.
- If any condition fails, the entire transaction is rejected.

## 8. Reversal Policy
- Reversal is the only architecturally approved method for correcting a posted `JournalEntry`.
- A reversal must clone the original entry's lines, invert the debit/credit application, and post as a completely new `JournalEntry`.
- The original entry is marked as `Reversed` and holds a reference to the ID of the reversing entry.
- The reversing entry holds a reference to the ID of the original entry.

## 9. Fiscal Period Policy
- Every `JournalEntry` must explicitly belong to a Fiscal Period.
- The date of the journal entry MUST fall within the start and end dates of its assigned Fiscal Period.
- The GL domain enforces fiscal period locking; posting is rejected if the period is locked or closed.

## 10. Currency Policy
- A `JournalEntry` MUST balance in the system's Base Currency.
- The GL enforces the balance rule explicitly on the base currency amounts.
- If foreign currency transactions are involved, the lines must carry both the foreign amount and the exact converted base amount used to achieve the balance.

## 11. Security Rules
- Only users with specific GL/Finance permissions (e.g., Accountant, Controller) can manually create or post journal entries.
- Automated posting via the Posting Engine is authorized via internal domain service contracts, not user UI sessions.
- All operations are strictly isolated by `business_id`.

## 12. Audit Trail
- A comprehensive timestamp history (`created_at`, `posted_at`, `reversed_at`) must be maintained.
- The `created_by` and `posted_by` user identifiers must be permanently recorded.
- The `JournalEntry` must utilize the Financial Document Policy (polymorphic references) to link back to the originating operational document (e.g., Sales Invoice, Payment).

## 13. Ownership Rules
- The `JournalEntry` Aggregate Root is the exclusive owner of all its child `JournalEntryLines`.
- `JournalEntryLines` cannot be created, modified, deleted, or queried independently of their parent `JournalEntry`.
- All operations to add or adjust lines MUST be routed through the `JournalEntry` aggregate boundary prior to posting.

## 14. Dependencies
- **Platform Foundation:** For core entity structures, UUIDs, and multi-tenancy.
- **Shared Value Objects:** For precise money and currency representation.
- **Finance Foundation:** For the Chart of Accounts and Fiscal Periods.
- **Posting Engine Architecture:** As the primary orchestration layer that generates and submits `JournalEntry` aggregates.

## 15. Out Of Scope
- **Sales:** Generating revenue invoices or calculating sales tax.
- **Purchasing:** Generating purchase orders or supplier bills.
- **Payments:** Moving actual funds, handling credit cards, or bank transfers.
- **Banking:** Bank statement reconciliation.
- **Cash Management:** Tracking physical drawer balances.
- **Accounts Receivable:** Managing customer aging or statements.
- **Accounts Payable:** Managing supplier aging or terms.
