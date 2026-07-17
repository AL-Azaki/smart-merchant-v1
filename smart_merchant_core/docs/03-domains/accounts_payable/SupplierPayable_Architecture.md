# SupplierPayable Architecture

## 1. Purpose
The purpose of the `SupplierPayable` Aggregate Root is to represent and track the official outstanding financial obligation owed by the business to a specific supplier. It serves as the primary entity for managing debt lifecycles, tracking payment terms, driving aging analysis, and maintaining the authoritative current balance of what the business owes.

## 2. Responsibilities
- **Track Outstanding Balance:** Maintain an accurate, real-time calculation of the total amount owed to the supplier.
- **Manage Payable Lifecycle:** Control the state of the debt (e.g., Open, Partially Paid, Fully Paid, Overdue, Written Off).
- **Own Payable Entries:** Act as the exclusive parent and gatekeeper for all individual payable entries/transactions that impact the balance.
- **Monitor Payment Obligations:** Ensure the business tracks its financial commitments against agreed payment terms.
- **Support Aging Analysis:** Provide the necessary data foundation (due dates, original amounts, remaining amounts) to classify debt by age.
- **Support Write-offs and Adjustments:** Facilitate the safe, auditable reduction or modification of debt outside of standard payment flows.

## 3. Entity Classification
- **Classification:** Aggregate Root
- **Domain:** Accounts Payable

## 4. Relationships
- **Supplier:** A mandatory relationship. Every `SupplierPayable` belongs to exactly one supplier.
- **Business:** Scopes the payable to a specific tenant.
- **Branch:** Optional scoping to a specific physical or logical branch.
- **Currency:** The currency in which the payable balance is maintained.
- **Responsible User:** Optional tracking of the specific internal staff member responsible for authorizing or managing this payable.

## 5. Lifecycle
The `SupplierPayable` aggregate adheres to the following states:
- **Open:** The payable has an outstanding balance and the current date is on or before the due date.
- **Partially Paid:** A portion of the debt has been settled, but a non-zero balance remains. (Can be considered a sub-state of Open or Overdue).
- **Fully Paid:** The outstanding balance has been reduced to exactly zero.
- **Overdue:** The payable has an outstanding balance and the current date is past the due date.
- **Written Off:** The remaining balance has been officially forgiven or deemed cleared without an outflow of funds, closing the payable.

## 6. Business Rules
- One `SupplierPayable` is associated with exactly one supplier.
- The outstanding balance cannot become negative. Overpayments to a supplier must be handled as Supplier Credits (a separate concept) or immediately refunded.
- The supplier's agreed Payment Terms (e.g., Net 30, Net 60) must be respected and tracked.
- The outstanding balance can ONLY be modified through the creation of immutable child Payable Entries. Direct manipulation of the balance field is prohibited.

## 7. Outstanding Balance Policy
- The `current_balance` is a calculated value representing the net sum of all approved child payable entries (bills, payments, adjustments).
- It must accurately reflect the exact amount the business currently owes.
- The balance must be maintained atomically to prevent race conditions during concurrent payment or billing operations.

## 8. Payment Terms Policy
- The Aggregate Root is responsible for tracking payment terms negotiated with the supplier.
- The system must track the `due_date` calculated based on the origination date and the assigned payment terms.
- Payment Terms affect cash flow forecasting and dictate when the payable transitions to an `Overdue` state.

## 9. Aging Policy
- The Aggregate Root must track the `due_date` of the debt.
- Aging analysis is a read-model operation that calculates `current_date - due_date` to classify the debt into standard buckets (e.g., Current, 1-30 Days Past Due, 31-60 Days, 90+ Days).
- The state automatically logically transitions to `Overdue` when the due date passes and the balance is greater than zero.

## 10. Currency Policy
- The `SupplierPayable` balance is tracked in the system's Base Currency.
- If the originating transaction was in a foreign currency, the aggregate must store the original foreign currency amount, the foreign currency code, and the exchange rate used at the time of debt creation.

## 11. Security Rules
- Only users with specific Accounts Payable permissions can view, adjust, or write off payables.
- Writing off a payable requires elevated (managerial) privileges.
- All operations are strictly isolated by `business_id`.

## 12. Audit Trail
- Every `SupplierPayable` must record the `created_by` and `updated_by` user identifiers.
- A comprehensive timestamp history (`created_at`, `updated_at`, `closed_at`) must be maintained.
- State transitions (e.g., from Open to Written Off) must be logged and auditable.

## 13. Ownership Rules
- The `SupplierPayable` Aggregate Root is the exclusive owner of all its child Payable Entries.
- Payable Entries cannot exist independently of a `SupplierPayable`.
- All operations to add, adjust, or settle debt MUST be routed through the `SupplierPayable` aggregate boundary.

## 14. Dependencies
- **Platform Foundation:** For core entity structures, UUIDs, and multi-tenancy.
- **Shared Value Objects:** For standard representation of money and currency.
- **Purchasing Domain (Conceptual):** As the primary source of debt creation (Purchase Invoices/Bills).
- **Payments Domain (Conceptual):** As the primary source of debt reduction (Disbursements).

## 15. Out Of Scope
- **Payment Execution:** Processing checks, bank wires, or handling physical cash.
- **Journal Entries:** Generating GL postings for expense realization or accounts payable liabilities.
- **Cash Registers:** Tracking physical cash drawers.
- **Bank Accounts:** Tracking bank balances or statement reconciliation.
- **Purchase Invoice Creation:** Generating the actual line items, taxes, and PDFs for a supplier bill.
