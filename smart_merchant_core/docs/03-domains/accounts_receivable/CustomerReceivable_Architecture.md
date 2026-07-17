# CustomerReceivable Architecture

## 1. Purpose
The purpose of the `CustomerReceivable` Aggregate Root is to represent and track the official outstanding debt owed by a specific customer to the business. It serves as the primary entity for managing debt lifecycles, enforcing credit limits, driving aging analysis, and maintaining the authoritative current balance of what the customer owes.

## 2. Responsibilities
- **Track Outstanding Balance:** Maintain an accurate, real-time calculation of the total amount owed by the customer.
- **Manage Receivable Lifecycle:** Control the state of the debt (e.g., Open, Partially Paid, Fully Paid, Overdue, Written Off).
- **Own Receivable Entries:** Act as the exclusive parent and gatekeeper for all individual receivable entries/transactions that impact the balance.
- **Monitor Credit Exposure:** Enforce business credit limits by preventing operations that would exceed the customer's approved credit threshold.
- **Support Aging Analysis:** Provide the necessary data foundation (due dates, original amounts, remaining amounts) to classify debt by age.
- **Support Write-offs and Adjustments:** Facilitate the safe, auditable reduction or modification of debt outside of standard payment flows.

## 3. Entity Classification
- **Classification:** Aggregate Root
- **Domain:** Accounts Receivable

## 4. Relationships
- **Customer:** A mandatory relationship. Every `CustomerReceivable` belongs to exactly one customer.
- **Business:** Scopes the receivable to a specific tenant.
- **Branch:** Optional scoping to a specific physical or logical branch.
- **Currency:** The currency in which the receivable balance is maintained.
- **Responsible User:** Optional tracking of the specific staff member (e.g., account manager) responsible for managing/collecting this debt.

## 5. Lifecycle
The `CustomerReceivable` aggregate adheres to the following states:
- **Open:** The receivable has an outstanding balance and the current date is on or before the due date.
- **Partially Paid:** A portion of the debt has been settled, but a non-zero balance remains. (Can be considered a sub-state of Open or Overdue).
- **Fully Paid:** The outstanding balance has been reduced to exactly zero.
- **Overdue:** The receivable has an outstanding balance and the current date is past the due date.
- **Written Off:** The remaining balance has been officially forgiven or deemed uncollectible, closing the receivable without receiving funds.

## 6. Business Rules
- One `CustomerReceivable` is associated with exactly one customer. (A customer may have multiple separate receivables or one consolidated receivable, depending on future implementation design, but a receivable cannot belong to multiple customers).
- The outstanding balance cannot become negative. Overpayments must be handled as Customer Credits (a separate concept) or immediately refunded.
- The customer's approved Credit Limit must be strictly respected. Any action that increases the receivable balance beyond this limit must be rejected unless authorized by a deliberate override process.
- The outstanding balance can ONLY be modified through the creation of immutable child Receivable Entries. Direct manipulation of the balance field is prohibited.

## 7. Outstanding Balance Policy
- The `current_balance` is a calculated value representing the net sum of all approved child receivable entries (invoices, payments, adjustments).
- It must accurately reflect the exact amount the customer currently owes.
- The balance must be maintained atomically to prevent race conditions during concurrent payment or invoicing operations.

## 8. Credit Limit Policy
- The Aggregate Root is responsible for enforcing credit limits.
- Before accepting a new debt-increasing entry (e.g., a new sales invoice), the aggregate must verify that `current_balance + new_amount <= credit_limit`.
- Temporary overrides to the credit limit require explicit security authorization and must be audited.

## 9. Aging Policy
- The Aggregate Root must track the `due_date` of the debt.
- Aging analysis is a read-model operation that calculates `current_date - due_date` to classify the debt into standard buckets (e.g., Current, 1-30 Days Past Due, 31-60 Days, 90+ Days).
- The state automatically logically transitions to `Overdue` when the due date passes and the balance is greater than zero.

## 10. Currency Policy
- The `CustomerReceivable` balance is tracked in the system's Base Currency.
- If the originating transaction was in a foreign currency, the aggregate must store the original foreign currency amount, the foreign currency code, and the exchange rate used at the time of debt creation.

## 11. Security Rules
- Only users with specific Accounts Receivable permissions can view, adjust, or write off receivables.
- Writing off a receivable requires elevated (managerial) privileges.
- All operations are strictly isolated by `business_id`.

## 12. Audit Trail
- Every `CustomerReceivable` must record the `created_by` and `updated_by` user identifiers.
- A comprehensive timestamp history (`created_at`, `updated_at`, `closed_at`) must be maintained.
- State transitions (e.g., from Open to Written Off) must be logged and auditable.

## 13. Ownership Rules
- The `CustomerReceivable` Aggregate Root is the exclusive owner of all its child Receivable Entries.
- Receivable Entries cannot exist independently of a `CustomerReceivable`.
- All operations to add, adjust, or settle debt MUST be routed through the `CustomerReceivable` aggregate boundary.

## 14. Dependencies
- **Platform Foundation:** For core entity structures, UUIDs, and multi-tenancy.
- **Shared Value Objects:** For standard representation of money and currency.
- **Sales Domain (Conceptual):** As the primary source of debt creation (Invoices).
- **Payments Domain (Conceptual):** As the primary source of debt reduction (Receipts).

## 15. Out Of Scope
- **Payment Execution:** Processing credit cards or handling physical cash.
- **Journal Entries:** Generating GL postings for bad debt or revenue realization.
- **Cash Registers:** Tracking physical cash drawers.
- **Bank Accounts:** Tracking bank balances or statement reconciliation.
- **Sales Invoice Creation:** Generating the actual line items, taxes, and PDFs for a sale.
