# Cash Management Foundation Architecture

## 1. Purpose
The purpose of the Cash Management domain is to provide a robust, auditable, and immutable foundation for managing physical cash within the Smart Merchant ERP system. It ensures that every movement of cash—whether into, out of, or between cash registers and boxes—is strictly controlled, tracked, and reconciled.

## 2. Scope
The scope of this domain is strictly limited to managing the physical and operational lifecycle of cash assets. It encompasses:
- Cash Registers (Point of Sale tills)
- Cash Boxes (Main safes or central treasuries)
- Cash Transfers (Movement between registers/boxes)
- Cash Deposits (Adding cash from external sources)
- Cash Withdrawals (Removing cash to external destinations)
- Cash Adjustments (Correction of discrepancies)
- Opening Balance (Initial amount when opening a register/box)
- Closing Balance (Final amount when closing a register/box)

## 3. Domain Responsibilities
- **Cash Movement Management:** Tracking all inflows and outflows of cash accurately.
- **Box and Register Management:** Governing the logical containers of physical cash across branches.
- **Transfer Management:** Orchestrating and verifying the secure movement of cash between different internal cash containers.
- **Current Balance Tracking:** Maintaining a real-time, accurate reflection of cash available in any given register or box.
- **Shift/Session Lifecycle:** Managing the opening and closing procedures for cash registers to ensure accountability per user/shift.

## 4. Domain Boundaries
To maintain strict separation of concerns, the Cash Management domain **MUST NOT**:
- **Create Journal Entries Directly:** It cannot write directly to the general ledger; all accounting impacts must be routed through the Finance Posting Engine.
- **Manage Bank Accounts:** Bank accounts, digital transfers, and bank reconciliations are strictly part of the Finance/Banking domains.
- **Issue Invoices:** It does not handle Sales or Purchase invoicing.
- **Manage Customers/Suppliers:** It does not maintain or govern external contact master data.

## 5. Domain Principles
- **Cash Integrity:** The balance of any cash container must always be a mathematically provable sum of its immutable historical transactions.
- **Immutable Transactions:** Once a cash transaction is recorded, it cannot be altered or hard-deleted. Corrections must be made via compensatory adjustments (Reversals).
- **Auditable:** Every cash movement must record who initiated it, who approved it (if applicable), when it happened, and why.
- **Tenant Aware:** All cash containers and transactions must strictly belong to a specific Business and Branch.
- **Event Driven:** State changes (e.g., Register Closed, Cash Transferred) must emit Domain Events to notify other domains (e.g., Notifications, Observability) without synchronous coupling.

## 6. Aggregate Roots
The domain is structured around the following expected Aggregate Roots:
- **CashRegister:** Represents a physical till or main safe, holding its state (Open, Closed), assigned currency, and current calculated balance.
- **CashTransaction:** Represents an immutable movement of money (Transfer, Deposit, Withdrawal, Adjustment) affecting one or more Cash Registers.

## 7. Lifecycle Principles
- **Strict Session Control:** A Cash Register cannot process transactions unless it is in an "Open" state.
- **Reconciliation Checkpoint:** The "Closing" of a Cash Register acts as a financial checkpoint. It requires a declaration of physical cash counted, calculating any discrepancies (shortages/overages) automatically.
- **Transfer Handshake:** Cash transfers between registers may require a two-step lifecycle (Initiated -> Accepted/Rejected) to ensure physical custody is verified.

## 8. Currency Principles
- **Single Base Currency per Register:** Each Cash Register operates in a designated base currency.
- **Multi-Currency Transactions:** If a register accepts foreign currency, the system must record the transaction in the foreign currency while immediately calculating and storing the base equivalent using an official Exchange Rate.
- **No Currency Revaluation:** Realized exchange gains or losses during cash transactions must be calculated at the point of transaction, not revalued continuously.

## 9. Finance Relationship
- **Dependency via Posting Engine:** The Cash Management domain must use the standard `PostingEngineInterface` to translate cash transactions into Journal Entries.
- **Account Mapping:** The domain will utilize the `AccountMapping` service to determine the correct Chart of Accounts for Cash, Overages, and Shortages without hardcoding account numbers.

## 10. Payments Relationship
- **Consumer of Payments:** When the Payments domain processes a cash receipt or cash payment, it instructs the Cash Management domain to update the respective Cash Register balance.
- **Decoupled Operation:** Cash Management handles the *storage* and *counting* of the physical cash, while Payments handles the *settlement* of business debt.

## 11. Audit Principles
- **No Soft Deletes:** Historical cash transaction records must be permanently retained for legal and financial compliance.
- **Traceability:** Every `CashTransaction` must have a traceable reference to its source document (e.g., `Payment ID`, `Expense ID`, `Manual Entry`).
- **Snapshotting:** Closing a register creates an immutable snapshot of the balance at that exact moment in time.

## 12. Security Principles
- **Role-Based Execution:** Opening/Closing registers, performing adjustments, and approving transfers must be protected by strict authorization policies.
- **Branch Isolation:** Users can only view or interact with Cash Registers assigned to their authorized Branch.
- **Tamper Evident:** High-value transactions or manual adjustments may require secondary approval or trigger immediate security notifications.

## 13. Dependencies
- **Platform Authorization:** For role and permission enforcement.
- **Shared Financial Documents:** For linking cash movements to standard reference documents.
- **System Domain Events:** For broadcasting lifecycle changes.
- **Finance Domain:** Specifically the `Posting Engine` and `Account Mapping` services.

## 14. Out Of Scope
- **Bank Reconciliation:** Matching cash book entries with bank statements.
- **Digital Payment Gateways:** Credit cards, Stripe, PayPal, etc.
- **Expense Management Workflow:** Approving employee expenses (this belongs to an HR/Expense domain).
- **Point of Sale (POS) UI:** The actual visual interface of the checkout counter.
