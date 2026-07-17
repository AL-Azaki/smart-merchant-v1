# Accounts Receivable (AR) Foundation Architecture

## 1. Purpose
The purpose of the Accounts Receivable (AR) Domain is to manage, track, and enforce all customer debts owed to the business. It acts as the central authority for tracking outstanding balances, managing due dates, analyzing aging debt, generating customer statements, and enforcing credit limits, ensuring complete transparency and financial control over incoming receivables.

## 2. Scope
The scope of the Accounts Receivable Domain encompasses:
- **Customer Receivables:** Tracking all monetary amounts owed by customers.
- **Outstanding Balances:** Maintaining accurate, real-time balances of what is owed.
- **Customer Statements:** Generating point-in-time statements of customer debt.
- **Due Dates:** Tracking and enforcing payment deadlines.
- **Aging:** Categorizing debts based on how long they have been outstanding (e.g., 30, 60, 90+ days).
- **Credit Limits:** Monitoring customer balances against pre-approved credit boundaries.
- **Receivable Adjustments:** Managing non-payment reductions or increases (e.g., early payment discounts, late fees).
- **Write-offs:** Handling uncollectible debts in a traceable, auditable manner.

## 3. Domain Responsibilities
- **Debt Tracking:** Maintaining the authoritative record of all outstanding customer debt.
- **Credit Enforcement:** Providing current balance and credit limit status to other domains (e.g., Sales) to authorize or block new transactions.
- **Aging Analysis:** Providing accurate aging reports to identify overdue accounts.
- **Statement Generation:** Producing accurate, immutable statements for customer communication and debt collection.
- **Adjustment Tracking:** Safely recording any modifications to expected receivables that are not direct payments.

## 4. Domain Boundaries
To maintain strict domain isolation, Accounts Receivable MUST NOT:
- **Create Sales Invoices:** Invoicing is the exclusive responsibility of the Sales Domain.
- **Receive Payments:** Processing incoming funds belongs entirely to the Payments Domain.
- **Manage Cash Registers:** Physical cash handling belongs to the Cash Management Domain.
- **Manage Bank Accounts:** Bank transactions and balances belong to the Banking Domain.
- **Create Journal Entries:** General Ledger postings are the exclusive responsibility of the Finance Domain.

## 5. Domain Principles
- **Customer Debt Tracking:** All tracking is centered around the Customer as the primary debt holder.
- **Immutable Financial History:** Once a receivable or adjustment is recorded, it cannot be modified or soft-deleted. Corrective actions must use compensatory entries.
- **Tenant Isolation:** All receivable records must be strictly isolated by `business_id`.
- **Event-Driven Integration:** AR responds to events from Sales (new invoices) and Payments (incoming receipts) to update balances asynchronously where appropriate, or synchronously via designated integration boundaries.
- **Auditability:** Every change to a customer's receivable balance must be fully traceable to the user, the time, and the originating document.

## 6. Aggregate Roots
The expected Aggregate Roots for this domain are:
- **CustomerReceivable:** The primary aggregate representing the overall debt profile, current balance, and credit limit of a specific customer.
- **ReceivableStatement:** An aggregate representing an immutable snapshot of a customer's debt at a specific point in time, used for reporting and collection.

*(Note: Exact internal entities and relationships will be defined in subsequent architectural documents.)*

## 7. Lifecycle Principles
Receivables generally follow these lifecycle states:
- **Open:** The receivable is outstanding and within its allowed payment terms.
- **Partially Paid:** A portion of the receivable has been settled, but a balance remains.
- **Fully Paid:** The receivable has been completely settled.
- **Overdue:** The receivable has not been paid by its designated due date.
- **Written Off:** The receivable has been deemed uncollectible and officially removed from expected cash flow.

## 8. Currency Principles
- **Base Currency Operations:** All core receivable tracking, credit limits, and aging analyses must be performed in the system's base currency.
- **Original Currency Tracking:** If a debt originates in a foreign currency, the original currency amount and the exchange rate at the time of origination must be recorded for accurate realization of foreign exchange gains/losses upon settlement.

## 9. Sales Relationship
- **Event Source:** Sales Invoices are the primary source of new accounts receivable.
- **Validation:** Sales relies on AR to validate if a customer has sufficient available credit before approving credit sales.
- **Loose Coupling:** AR tracks the debt using the Financial Document Policy (polymorphic references), remaining decoupled from the internal structure of Sales Invoices.

## 10. Payments Relationship
- **Event Source:** Payments (Receipts) are the primary mechanism for reducing accounts receivable balances.
- **Allocation:** Payments informs AR which specific debts are being settled.
- **Loose Coupling:** AR updates its balances based on Payment outcomes without managing the payment methods or settlement processes.

## 11. Finance Relationship
- **Posting Delegation:** Any receivable adjustments or write-offs that impact the General Ledger must be delegated to the Finance Domain's Posting Engine. AR never writes directly to the GL.
- **Chart of Accounts:** AR relies on the Finance Domain for Account Mappings (e.g., Accounts Receivable Asset Account, Bad Debt Expense Account).

## 12. Banking Relationship
- **No Direct Relationship:** AR has no direct interaction with Bank Accounts or Bank Transactions. All banking impacts occur via the Payments domain.

## 13. Cash Management Relationship
- **No Direct Relationship:** AR has no direct interaction with Cash Registers or Cash Transactions. All cash impacts occur via the Payments domain.

## 14. Audit Principles
- **Traceability:** Every modification to a receivable balance must record the `created_by` user and timestamp.
- **Immutability:** Financial records cannot be altered post-commit.
- **Document Linking:** Every receivable entry must point back to the originating Financial Document (e.g., Invoice, Payment, Adjustment) that caused it.

## 15. Security Principles
- **Authorization:** Only users with specific AR privileges (e.g., Finance Manager, Credit Controller) can authorize adjustments, write-offs, or credit limit changes.
- **Tenant Security:** Enforced `business_id` scoping on all queries and operations.

## 16. Dependencies
- **Platform Foundation:** For UUID generation, offline-first structures, and tenant isolation.
- **Financial Documents Foundation:** For the standard polymorphic linking to source documents.
- **Shared Value Objects:** For consistent monetary, currency, and date representations.

## 17. Out Of Scope
- **Payment Processing:** Processing credit cards, cash, or bank transfers.
- **Invoicing:** Creating, printing, or emailing Sales Invoices.
- **General Ledger Accounting:** Creating journal entries or managing the Chart of Accounts.
- **Supplier Payables:** Managing debts owed *by* the business (belongs to Accounts Payable).
- **Inventory Deductions:** Managing stock levels based on sales.
