# JournalEntryLine Architecture

## 1. Purpose
The purpose of the `JournalEntryLine` entity is to represent a single, atomic financial movement (a debit or a credit) against a specific account within the Chart of Accounts. It acts as the fundamental building block of double-entry accounting, providing the precise data required for Trial Balances, Income Statements, and Balance Sheets.

## 2. Responsibilities
- **Record Individual Debit and Credit Lines:** Store the specific monetary impact on a single account.
- **Reference the Accounting Account:** Link directly to the authoritative Chart of Account that is being modified.
- **Preserve Accounting Accuracy:** Maintain the exact amounts needed to prove the overall `JournalEntry` is balanced.
- **Participate in Balanced Journal Entries:** Act as the constituents that the `JournalEntry` sums together to validate mathematical correctness.
- **Support Financial Reporting:** Provide the granular, immutable data necessary for all downstream financial aggregation and reporting.

## 3. Entity Classification
- **Classification:** Child Entity
- **Domain:** General Ledger (GL)
- **Important:** It is strictly a Child Entity and NEVER an Aggregate Root. It cannot exist independently of a `JournalEntry`.

## 4. Relationships
- **JournalEntry (Parent/Owner):** A mandatory, direct hierarchical relationship. Every `JournalEntryLine` must belong to exactly one `JournalEntry`.
- **ChartOfAccount:** A mandatory reference to the specific GL account being debited or credited.
- **Financial Document (Polymorphic Reference):** An optional, generic reference linking this specific line to an underlying source document (e.g., the specific invoice line or payment record that generated this ledger line).

## 5. Lifecycle
- The lifecycle of a `JournalEntryLine` is entirely bounded by and subordinate to its parent `JournalEntry`.
- It cannot be created, posted, modified, or reversed independently of its parent aggregate.
- Once the parent `JournalEntry` transitions to `Posted`, the `JournalEntryLine` enters an **immutable** state.

## 6. Business Rules
- Every `JournalEntryLine` MUST belong to exactly one `JournalEntry`.
- Every `JournalEntryLine` MUST reference exactly one valid, active `ChartOfAccount` at the time of creation.
- A line MUST represent strictly a Debit OR a Credit (enforced via mutually exclusive fields or a strict direction enumerator).
- Posted lines are permanently immutable.
- The parent `JournalEntry` balance is exclusively calculated by aggregating the values of all its child `JournalEntryLines`.

## 7. Debit/Credit Policy
- A `JournalEntryLine` must clearly distinguish whether it is a Debit or a Credit.
- Amounts stored in the line must always be **positive values**. The impact (addition or subtraction) on the account balance is determined by the account's normal balance type (Asset/Expense vs. Liability/Equity/Revenue) combined with the line's Debit/Credit designation.
- A single `JournalEntryLine` cannot contain mixed debit and credit values (e.g., a line cannot have a debit of 100 and a credit of 50 simultaneously).

## 8. Financial Document Policy
- A `JournalEntryLine` may reference any system-approved operational document without being tightly coupled to a specific domain's internal structures.
- This is implemented using the generic `Financial Document Policy` (polymorphic tracking via `document_type` and `document_id`).
- This design ensures the GL Domain remains completely agnostic to the internal database schemas of Sales, Purchasing, Payments, Banking, Cash Management, Accounts Receivable, or Accounts Payable.

## 9. Currency Policy
- A `JournalEntryLine` must store its value in the system's Base Currency to ensure the ledger can be mathematically balanced.
- If the original transaction occurred in a foreign currency, the line must also store the foreign currency amount, the foreign currency code, and the exchange rate applied.

## 10. Ownership Rules
- The `JournalEntry` Aggregate Root is the sole and exclusive owner of the `JournalEntryLine`.
- All operations (Create, Read, Validate) on a `JournalEntryLine` must be routed through the parent `JournalEntry`.
- It is architecturally prohibited to operate on a `JournalEntryLine` directly via a dedicated API, Controller, or Repository.

## 11. Audit Trail
- A `JournalEntryLine` inherits its primary auditability from the parent `JournalEntry` (which tracks `created_by` and timestamps).
- The line must maintain the polymorphic link (`document_type`, `document_id`) to provide a traceable path back to the exact operational event that caused the ledger impact.

## 12. Immutability Rules
- `JournalEntryLine` is inherently and permanently immutable once the parent `JournalEntry` is posted.
- `SoftDeletes` are strictly prohibited.
- Direct `UPDATE` operations on any financial or structural fields are strictly prohibited.
- If a line is incorrect, the entire parent `JournalEntry` must be reversed via a new compensating entry.

## 13. Dependencies
- **JournalEntry Architecture:** The parent Aggregate Root that governs the line's state and balance validation.
- **Finance Foundation:** For the `ChartOfAccount` definitions.
- **Financial Documents Foundation:** For the standard polymorphic document linking strategy.
- **Shared Value Objects Foundation:** For consistent monetary and currency value representations.

## 14. Out Of Scope
- **Posting Engine Implementation:** The logic that generates the lines from operational events belongs to the Finance Posting Engine.
- **Account Mapping:** The rules for determining *which* account to hit belong to the Finance mapping services, not the line entity itself.
- **Payment Execution:** Handling actual money movement.
- **Business Workflows:** Approvals for invoices or expenditures.
