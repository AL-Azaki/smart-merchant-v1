# BankAccount Architecture

## 1. Purpose
The purpose of the `BankAccount` Aggregate Root is to represent a single, official company bank account within the system. It acts as the authoritative source of truth for the account's current balance, owns all financial transactions against it, and enforces all banking rules including lifecycle restrictions, currency constraints, and reconciliation boundaries.

## 2. Responsibilities
- **Account Information Management:** Maintaining the bank account's metadata including account number, IBAN, bank name, and display name.
- **Balance Maintenance:** Maintaining an always-accurate current balance, calculated exclusively through owned `BankTransaction` child entities.
- **Transaction Ownership:** Acting as the sole owner and gatekeeper for all `BankTransaction` entities linked to this account.
- **Deposit and Withdrawal Support:** Accepting inflow and outflow transaction requests and delegating them to its child `BankTransaction` entities.
- **Transfer Support:** Acting as the source or destination of a `BankTransfer` operation, ensuring its balance is updated atomically.
- **Reconciliation Support:** Providing the transaction data required for the `BankReconciliation` Aggregate to match against official bank statements.

## 3. Entity Classification
- **Classification:** Aggregate Root
- **Domain:** Banking

## 4. Relationships
The `BankAccount` interacts with the following conceptual entities:
- **Business:** The owning tenant. A `BankAccount` strictly belongs to one Business.
- **Branch:** An optional organizational association to a specific branch or cost center.
- **Currency:** The mandatory base currency in which the account operates.
- **Bank (Institution):** A reference to the banking institution (e.g., bank name, swift code). This is metadata, not a domain relationship.
- **Responsible User:** An optional reference to the employee or user who is the account manager or primary custodian.

## 5. Lifecycle
The `BankAccount` follows a formal lifecycle with three recognized states:

- **Active:** The account is fully operational. It can receive deposits, withdrawals, and transfers. All transaction types are permitted.
- **Frozen:** The account is temporarily restricted. Existing balances are preserved, but no new debit transactions are permitted. Credit transactions (incoming funds) may still be allowed depending on configuration. This state is typically used during an audit or investigation.
- **Closed:** The account has been permanently deactivated. No new transactions of any kind are permitted. The account and all its historical data are permanently retained for audit and compliance purposes. A `Closed` account cannot be re-activated.

## 6. Business Rules
- A `BankAccount` MUST belong to exactly one `Business`.
- A `BankAccount` MUST be assigned exactly one base `Currency`.
- A `BankAccount` in `Closed` or `Frozen` state cannot have debit transactions executed against it.
- A `Closed` `BankAccount` cannot receive any transactions whatsoever.
- The `current_balance` of the account must at all times equal: Opening Balance + Sum of all credited `BankTransaction` amounts - Sum of all debited `BankTransaction` amounts.
- Balance changes are ONLY permitted via the creation of a `BankTransaction` child entity; direct balance manipulation is strictly prohibited.
- A `BankAccount` cannot be fully closed if it has an unreconciled open `BankReconciliation` session.

## 7. Opening Balance Policy
- When a `BankAccount` is created, an opening balance must be declared.
- This opening balance is recorded as an initial `BankTransaction` of type `OpeningBalance` to maintain full mathematical integrity of the transaction history.
- The opening balance date is mandatory and represents the starting point for all reconciliation purposes.

## 8. Current Balance Policy
- The `current_balance` field is a derived, maintained value — it is not calculated on-the-fly from raw transaction queries.
- It is updated atomically each time a `BankTransaction` is successfully committed.
- The balance is always maintained in the account's base `Currency`.
- For foreign currency transactions, the base-equivalent amount is calculated at the point of the transaction using the official Exchange Rate and stored immutably.

## 9. Reconciliation Policy
- A `BankAccount` can have at most one active (open) `BankReconciliation` session at a time.
- The `BankReconciliation` Aggregate is a separate entity; `BankAccount` does not own it. Instead, the `BankReconciliation` references the `BankAccount`.
- The `BankAccount` must expose its transaction data to the `BankReconciliation` process without the reconciliation process directly modifying the account's balance.
- A `BankAccount` must track its last reconciled balance and date as a snapshot for auditing.

## 10. Currency Policy
- The `BankAccount` has a single, immutable **Base Currency** assigned at creation. It cannot be changed after the first transaction is recorded.
- All balances are maintained in the base currency.
- Foreign currency transactions must supply the exchange rate at the time of execution. The base-equivalent impact on the `current_balance` is calculated and stored immediately. No continuous revaluation occurs.

## 11. Security Rules
- Only users with authorized roles (e.g., Finance Manager, Accountant) can create or modify a `BankAccount`.
- Users can only view or operate on `BankAccount`s belonging to their authorized `Business`.
- The ability to `Freeze` or `Close` an account requires elevated permissions (e.g., Finance Director or System Administrator role).
- All exports or imports of bank statement data must be authenticated and logged.

## 12. Audit Trail
- Every state change to the `BankAccount` (creation, activation, freezing, closure) must be logged with the `created_by` user, `updated_by` user, and corresponding timestamps.
- Every `BankTransaction` that impacts the balance is itself an immutable audit record.
- The last reconciled balance and date must be stored directly on the `BankAccount` record as a point-in-time audit snapshot.

## 13. Ownership Rules
- The `BankAccount` is the **sole owner** of its `BankTransaction` child entities.
- All `BankTransaction` records must be accessed through or in context of their parent `BankAccount`.
- A `BankTransaction` cannot exist independently without a parent `BankAccount`.
- The `BankTransfer` Aggregate references two `BankAccount` Aggregate Roots but does not own them; it coordinates a state change across both.

## 14. Dependencies
- **Platform Tenant Foundation:** For Business and Branch isolation.
- **Platform Authorization Foundation:** For enforcing user roles and permissions.
- **Shared Financial Documents Foundation:** For polymorphic linking of transactions to source documents.
- **Shared Value Objects Foundation:** For monetary and currency value representation.
- **Finance Domain (Currency):** For validating the assigned base currency.
- **System Domain Events Foundation:** For broadcasting lifecycle changes post-commit.

## 15. Out Of Scope
- **Journal Entry Creation:** Posting to the General Ledger is the exclusive responsibility of the Finance Domain's Posting Engine.
- **Cash Register Management:** Physical cash in tills and safes belongs to the Cash Management Domain.
- **Payment Invoice Processing:** Settling customer or supplier invoices belongs to the Payments Domain.
- **External Banking API Connectivity:** Real-time integration with online banking APIs (e.g., Open Banking, Plaid) is out of scope for this domain version.
- **Loan and Credit Line Management:** Banking facility management is outside this domain's boundaries.
- **Investment Account Management:** Portfolio and securities management are out of scope.
