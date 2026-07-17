# Banking Foundation Architecture

## 1. Purpose
The purpose of the Banking Domain is to provide a structured, auditable, and secure system for managing the company's bank accounts and all associated financial movements. It serves as the authoritative ledger for all bank-related activities, enabling accurate bank reconciliation, real-time balance tracking, and full traceability of every banking operation within the Smart Merchant ERP ecosystem.

## 2. Scope
The scope of this domain is strictly limited to managing the lifecycle of bank-related assets and operations. It encompasses:
- **Bank Accounts:** Managing company bank account definitions and their current balances.
- **Bank Transactions:** Recording all movements (credits and debits) affecting a bank account.
- **Bank Transfers:** Orchestrating the movement of funds between two internal bank accounts.
- **Bank Deposits:** Recording external cash or check deposits into a bank account.
- **Bank Withdrawals:** Recording the removal of funds from a bank account.
- **Bank Reconciliation:** The formal process of matching bank account transactions against official bank statements.
- **Bank Statements:** Importing and managing official bank statement data for reconciliation purposes.

## 3. Domain Responsibilities
- **Account Management:** Maintaining the registry of all company bank accounts with their metadata, currency, and current balance.
- **Transaction Recording:** Providing an immutable log of every credit and debit transaction against any bank account.
- **Transfer Orchestration:** Managing the two-sided entry for internal fund transfers (debit source, credit destination).
- **Balance Maintenance:** Continuously maintaining an accurate current balance for each bank account based on the sum of its immutable transactions.
- **Reconciliation Management:** Governing the formal session-based process of matching system transactions against bank statement lines.
- **Statement Management:** Ingesting, storing, and parsing bank statement data to support the reconciliation process.

## 4. Domain Boundaries
To maintain strict separation of concerns, the Banking Domain **MUST NOT**:
- **Create Journal Entries Directly:** All accounting postings must be routed through the Finance Domain's `PostingEngineInterface`.
- **Manage Cash Registers or Cash Boxes:** Physical cash management belongs exclusively to the Cash Management Domain.
- **Manage Payments:** The settlement of business invoices (Accounts Receivable/Payable) belongs to the Payments Domain.
- **Manage Customers or Suppliers:** Master data management belongs to the Sales and Purchasing Domains respectively.
- **Initiate Financial Documents:** It does not issue invoices or create payment orders; it only reflects the resulting bank movements.

## 5. Domain Principles
- **Bank Integrity:** The balance of any bank account must always be mathematically provable from its immutable transaction history.
- **Immutable Transactions:** Once a bank transaction is committed, it cannot be altered or hard-deleted. Corrections require a compensatory reversal transaction.
- **Auditable:** Every bank movement must record who created it, when it was created, and its originating source document.
- **Tenant Isolation:** All bank accounts and transactions are strictly scoped to a specific Business, ensuring no cross-tenant data leakage.
- **Event Driven:** Significant state changes (e.g., Reconciliation Completed, Transfer Approved) must emit Domain Events to notify other domains asynchronously.

## 6. Aggregate Roots
The domain is structured around the following expected Aggregate Roots:
- **BankAccount:** The primary Aggregate Root representing a single company bank account. It governs its own state, balance, and owns its child `BankTransaction` entities.
- **BankTransfer:** Represents an atomic, two-sided transfer operation between two `BankAccount` aggregates, ensuring both sides are committed atomically or not at all.
- **BankReconciliation:** Represents a formal reconciliation session tied to a specific `BankAccount` and a date range, containing matched and unmatched items.

## 7. Lifecycle Principles
- **Account Activation:** A Bank Account must be explicitly activated before it can receive or process any transactions.
- **Account Deactivation:** A Bank Account can be deactivated (logically closed) but its historical data must remain permanently.
- **Transfer States:** A Bank Transfer must follow a strict lifecycle (e.g., Pending → Executed/Failed) to ensure fund integrity.
- **Reconciliation Session:** A Reconciliation session must be explicitly opened and closed. Once closed and approved, it becomes an immutable historical record.

## 8. Currency Principles
- **Single Base Currency per Account:** Each Bank Account operates in a designated base currency.
- **Multi-Currency Awareness:** The system must record both the foreign currency amount and the base-equivalent amount for cross-currency transactions using the official Exchange Rate at the time of the transaction.
- **No Currency Revaluation Within Domain:** Exchange gains/losses are recognized at the point of transaction and are not continuously revalued by this domain.

## 9. Finance Relationship
- **Mandatory via Posting Engine:** Every bank transaction that has an accounting impact must trigger a posting via the `PostingEngineInterface`. The Banking Domain never writes directly to the Journal.
- **Account Mapping:** The domain uses the `AccountMapping` service to determine the correct Chart of Accounts for bank assets, transfer clearing, and exchange differences without hardcoding account numbers.

## 10. Cash Management Relationship
- **Complementary, Not Overlapping:** The Banking Domain manages digital fund movements in bank accounts, while Cash Management manages physical cash in registers. They are sibling domains with no direct dependency.
- **Bank Deposit Integration Point:** When cash is deposited from a Cash Register into a Bank Account, this action is the integration boundary — Cash Management records the outflow, and Banking records the inflow. Both operations must occur atomically.

## 11. Payments Relationship
- **Consumer Integration:** When the Payments Domain processes a bank payment or bank receipt, it instructs the Banking Domain to record the corresponding `BankTransaction` via an interface contract.
- **Strict Decoupling:** The Payments Domain does not directly modify `BankAccount` balances. It only communicates through the Banking Domain's official interface.

## 12. Audit Principles
- **No Soft Deletes:** Bank transaction records must be permanently retained for legal, tax, and regulatory compliance.
- **Full Traceability:** Every `BankTransaction` must be linked to its originating source document (e.g., `Payment ID`, `Transfer ID`, `Reconciliation Adjustment`) using the standard Financial Document polymorphic pattern.
- **Reconciliation Snapshots:** A closed `BankReconciliation` creates an immutable point-in-time record of the account's reconciled balance.

## 13. Security Principles
- **Role-Based Access:** Operations such as creating bank accounts, executing transfers, and approving reconciliations must be protected by strict authorization policies.
- **Business Isolation:** Users can only access bank accounts that belong to their authorized Business.
- **High-Value Transaction Alerts:** Transfers above a configurable threshold may require dual authorization or trigger an immediate security notification.
- **Statement Import Validation:** Imported bank statement files must be validated and checksummed to prevent data tampering.

## 14. Dependencies
- **Platform Tenant Foundation:** For Business isolation enforcement.
- **Platform Authorization Foundation:** For role and permission enforcement.
- **Shared Financial Documents Foundation:** For the standard polymorphic document linking strategy.
- **Shared Value Objects Foundation:** For consistent monetary and currency value representations.
- **System Domain Events Foundation:** For broadcasting lifecycle changes post-commit.
- **Finance Domain:** Specifically the `Posting Engine` and `Account Mapping` services.

## 15. Out Of Scope
- **Cash Register Management:** Physical cash belongs entirely to the Cash Management Domain.
- **Payment Processing:** Settling invoices, managing receivables/payables belongs to the Payments Domain.
- **Investment Accounts:** Investment portfolios and financial instruments are beyond the scope of this domain.
- **Loan Management:** Credit lines, loan repayments, and debt tracking are out of scope.
- **Payroll Processing:** Employee salary disbursement management belongs to the HR/Payroll Domain.
- **Point of Sale Transactions:** POS-level cash and card processing belongs to the Sales and Cash Management Domains.
