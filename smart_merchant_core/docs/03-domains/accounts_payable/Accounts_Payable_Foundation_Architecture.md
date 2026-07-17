# Accounts Payable (AP) Foundation Architecture

## 1. Purpose
The purpose of the Accounts Payable (AP) Domain is to manage, track, and fulfill all financial obligations and debts owed by the business to its suppliers and vendors. It serves as the authoritative source for tracking outstanding balances, managing due dates, analyzing aging payables, enforcing payment terms, and providing supplier statements, ensuring accurate and transparent outbound cash flow management.

## 2. Scope
The scope of the Accounts Payable Domain encompasses:
- **Supplier Payables:** Tracking all monetary amounts the business owes to external suppliers.
- **Outstanding Balances:** Maintaining accurate, real-time balances of all debts.
- **Supplier Statements:** Generating point-in-time statements representing the business's debt to a supplier.
- **Due Dates:** Tracking and enforcing payment deadlines to avoid late fees or strained relationships.
- **Aging:** Categorizing payable debt based on its time outstanding (e.g., 30, 60, 90+ days).
- **Payment Terms:** Tracking standard payment timelines (e.g., Net 30, Net 60) for cash flow projection.
- **Payable Adjustments:** Managing non-payment reductions or increases (e.g., early payment discounts, late penalties).
- **Write-offs:** Handling debt forgiveness or formally cleared unpayable debts in a strictly auditable manner.

## 3. Domain Responsibilities
- **Debt Tracking:** Maintaining the definitive ledger of all outstanding supplier debt.
- **Payment Readiness:** Providing accurate data on what is owed, when it is due, and to whom, to facilitate payment runs.
- **Aging Analysis:** Producing reports to manage upcoming cash flow requirements and avoid overdue accounts.
- **Statement Generation:** Reconciling internal records against external supplier statements.
- **Adjustment Tracking:** Safely recording any modifications to expected payables outside of standard invoice or payment processing.

## 4. Domain Boundaries
To maintain strict domain isolation and adhere to DDD boundaries, Accounts Payable MUST NOT:
- **Create Purchase Invoices:** Invoicing and receiving goods is the exclusive responsibility of the Purchasing Domain.
- **Execute Payments:** Processing outgoing funds or issuing checks belongs entirely to the Payments Domain.
- **Manage Cash Registers:** Physical cash handling belongs to the Cash Management Domain.
- **Manage Bank Accounts:** Bank transactions, wire transfers, and balances belong to the Banking Domain.
- **Create Journal Entries:** General Ledger postings are the exclusive responsibility of the Finance Domain's Posting Engine.

## 5. Domain Principles
- **Supplier Debt Tracking:** All tracking is centered around the Supplier as the primary debt holder.
- **Immutable Financial History:** Once a payable or adjustment is recorded, it cannot be modified or soft-deleted. Corrections must use compensatory entries (e.g., Reversals).
- **Tenant Isolation:** All payable records must be strictly isolated by `business_id` (multi-tenancy).
- **Event-Driven Integration:** AP responds to events from Purchasing (new bills) and Payments (outgoing settlements) to update balances asynchronously where appropriate, or synchronously via well-defined integration interfaces.
- **Auditability:** Every change to a supplier's payable balance must be fully traceable to the user, timestamp, and originating document.

## 6. Aggregate Roots
The expected Aggregate Roots for this domain are:
- **SupplierPayable:** The primary aggregate representing the overall debt profile and current balance owed to a specific supplier.
- **PayableStatement:** An aggregate representing an immutable snapshot of the business's debt to a supplier at a specific point in time.

*(Note: Exact internal entities and relationships will be defined in subsequent architectural documents.)*

## 7. Lifecycle Principles
Payables generally follow these lifecycle states:
- **Open:** The payable is outstanding and within its allowed payment terms.
- **Partially Paid:** A portion of the payable has been settled, but a balance remains.
- **Fully Paid:** The payable has been completely settled (balance is exactly zero).
- **Overdue:** The payable has not been paid by its designated due date.
- **Written Off:** The remaining balance has been officially cleared or forgiven without an outflow of funds.

## 8. Currency Principles
- **Base Currency Operations:** All core payable tracking and aging analyses must be performed in the system's base currency.
- **Original Currency Tracking:** If a debt originates in a foreign currency (e.g., international supplier), the original currency amount, code, and exchange rate must be recorded to correctly calculate foreign exchange gains/losses upon final settlement.

## 9. Purchasing Relationship
- **Event Source:** Purchase Invoices (Bills) are the primary source of new accounts payable.
- **Validation:** Purchasing may query AP to understand current exposure or overdue status with a supplier before placing new purchase orders.
- **Loose Coupling:** AP tracks the debt using the Financial Document Policy (polymorphic references), remaining decoupled from the internal structure of Purchase Invoices.

## 10. Payments Relationship
- **Event Source:** Outbound Payments (Disbursements) are the primary mechanism for reducing accounts payable balances.
- **Allocation:** Payments informs AP which specific debts are being settled.
- **Loose Coupling:** AP updates its balances based on Payment outcomes without managing the payment execution, gateways, or settlement processes.

## 11. Finance Relationship
- **Posting Delegation:** Any payable adjustments or write-offs that impact the General Ledger must be delegated to the Finance Domain's Posting Engine. AP never writes directly to the GL.
- **Chart of Accounts:** AP relies on the Finance Domain for Account Mappings (e.g., Accounts Payable Liability Account).

## 12. Banking Relationship
- **No Direct Relationship:** AP has no direct interaction with Bank Accounts or Bank Transactions. All banking impacts occur via the Payments domain executing a supplier settlement.

## 13. Cash Management Relationship
- **No Direct Relationship:** AP has no direct interaction with Cash Registers or Cash Transactions. All physical cash payouts occur via the Payments domain.

## 14. Audit Principles
- **Traceability:** Every modification to a payable balance must record the `created_by` user identifier and timestamp.
- **Immutability:** Financial records cannot be altered post-commit.
- **Document Linking:** Every payable entry must point back to the originating Financial Document (e.g., Bill, Payment, Adjustment) that caused it.

## 15. Security Principles
- **Authorization:** Only users with specific AP privileges (e.g., AP Clerk, Finance Manager) can view, adjust, or write off payables.
- **Tenant Security:** Strict `business_id` scoping is enforced on all queries and operations to prevent cross-tenant data leaks.

## 16. Dependencies
- **Platform Foundation:** For UUID generation, offline-first structures, and tenant isolation.
- **Financial Documents Foundation:** For the standard polymorphic linking to source documents.
- **Shared Value Objects:** For consistent monetary, currency, and date representations.

## 17. Out Of Scope
- **Payment Execution:** Processing bank transfers, writing checks, or handling cash.
- **Purchasing / Receiving:** Creating purchase orders, receiving inventory, or generating supplier bills.
- **General Ledger Accounting:** Creating journal entries or managing the Chart of Accounts.
- **Customer Receivables:** Managing debts owed *to* the business (belongs to Accounts Receivable).
- **Inventory Valuation:** Managing stock values or moving average costs.
