# General Ledger (GL) Foundation Architecture

## 1. Purpose
The purpose of the General Ledger (GL) Domain is to act as the authoritative financial core of the business, maintaining a complete, immutable, and strictly balanced record of all financial transactions. It is the ultimate source of truth for the financial state of the business, enabling the generation of critical financial statements and ensuring rigorous compliance with double-entry accounting principles.

## 2. Scope
The scope of the General Ledger Domain encompasses:
- **Journal Entries:** The creation, validation, and storage of all financial transactions.
- **Double-Entry Accounting:** Enforcing the fundamental rule that every transaction's total debits must exactly equal its total credits.
- **Posting:** The process of officially committing a journal entry to the ledger, making it immutable.
- **Ledger Integrity:** Ensuring that the overall ledger remains mathematically balanced at all times.
- **Trial Balance Support:** Providing the necessary transactional data to aggregate and verify account balances.
- **Financial Statement Support:** Serving as the data foundation for Income Statements, Balance Sheets, and Cash Flow Statements.
- **Fiscal Period Awareness:** Ensuring entries are recorded within valid, open accounting periods.
- **Reversal Support:** Providing a mechanism to correct errors by posting mathematically opposite, compensating entries rather than deleting historical data.

## 3. Domain Responsibilities
- **Transaction Recording:** Safely storing the debit and credit impacts on various financial accounts.
- **Validation:** Strictly verifying the mathematical balance of every journal entry before it is posted.
- **Historical Integrity:** Maintaining an unbreakable, append-only chain of financial history.
- **Period Enforcement:** Rejecting entries that attempt to post into closed or locked fiscal periods.

## 4. Domain Boundaries
To maintain its role strictly as the financial record-keeper, the General Ledger MUST NOT:
- **Create Sales Invoices:** Operational sales logic belongs to the Sales Domain.
- **Create Purchase Invoices:** Operational purchasing logic belongs to the Purchasing Domain.
- **Execute Payments:** Money movement belongs to the Payments Domain.
- **Manage Cash Registers:** Physical cash handling belongs to the Cash Management Domain.
- **Manage Bank Accounts:** Banking operations belong to the Banking Domain.
- **Manage Customer Receivables:** Tracking debt owed *to* the business belongs to the Accounts Receivable Domain.
- **Manage Supplier Payables:** Tracking debt owed *by* the business belongs to the Accounts Payable Domain.

## 5. Domain Principles
- **Double-Entry Accounting:** Every transaction must have at least two accounts involved, with total debits equaling total credits.
- **Every Journal Must Balance:** The GL rejects any journal entry where `sum(debits) ≠ sum(credits)`.
- **Immutable Posted Entries:** Once a journal entry is marked as Posted, its financial impact cannot be altered or soft-deleted.
- **Auditability:** Every journal entry must trace back to the user who created it and the operational document that triggered it.
- **Event Driven:** The GL receives posting requests from operational domains (via the Finance Posting Engine) and processes them synchronously or asynchronously based on configuration.
- **Tenant Isolation:** All ledger records are strictly isolated by `business_id` to guarantee multi-tenant security.

## 6. Aggregate Roots
The expected Aggregate Root for this domain is:
- **JournalEntry:** The primary entity representing a single, balanced financial transaction composed of multiple debit and credit lines.

*(Note: Exact internal entities and relationships will be defined in subsequent architectural documents.)*

## 7. Lifecycle Principles
Journal entries adhere to the following lifecycle states:
- **Draft:** The entry is being built, is not yet mathematically validated, and has not impacted account balances.
- **Posted:** The entry is validated, balanced, locked, and its financial impact is officially recorded in the ledger.
- **Reversed:** A posted entry that has been logically negated by a subsequent, linked compensating entry.

## 8. Posting Principles
- Posting is a one-way, atomic operation.
- A posting operation must lock the entry, validate its balance (`Debits = Credits`), and ensure the target fiscal period is open.
- If any validation fails, the entire transaction rolls back, and no partial entries are saved.

## 9. Fiscal Period Principles
- Every journal entry must be associated with a specific date that falls within a defined Fiscal Period.
- The GL must verify the status of the Fiscal Period before posting. If the period is closed, posting is rejected to prevent altering finalized financial statements.

## 10. Finance Relationship
- The General Ledger is a sub-domain/core component of the broader Finance architectural umbrella.
- It relies on the Finance Domain for the Chart of Accounts and the Posting Engine to route requests from operational domains.

## 11. Sales Relationship
- Sales generates revenue and accounts receivable entries, which are translated into posting requests and stored in the GL.

## 12. Purchasing Relationship
- Purchasing generates expense and accounts payable entries, which are translated into posting requests and stored in the GL.

## 13. Payments Relationship
- Outbound and inbound payments generate cash/bank clearing entries that the GL records to reflect the movement of funds.

## 14. Banking Relationship
- Bank transactions, fees, and settlements generate posting requests that the GL records to reflect actual bank balances.

## 15. Cash Management Relationship
- Cash register shifts, discrepancies, and payouts generate posting requests that the GL records to reflect physical cash on hand.

## 16. Accounts Receivable Relationship
- Accounts Receivable (AR) generates posting requests when customer debt is created, adjusted, or written off. The GL records these to update the AR Asset accounts.

## 17. Accounts Payable Relationship
- Accounts Payable (AP) generates posting requests when supplier debt is created, adjusted, or written off. The GL records these to update the AP Liability accounts.

## 18. Audit Principles
- **Traceability:** Every entry must record the `created_by` identifier.
- **Source Linking:** Every entry must contain polymorphic references (`document_type`, `document_id`) linking it back to the original operational document (e.g., Invoice, Payment).
- **Immutability:** Financial data is never overwritten.

## 19. Security Principles
- **Strict Authorization:** Direct manipulation of the GL (e.g., manual journal entries) requires the highest level of financial privilege (e.g., Financial Controller, Admin).
- **Tenant Security:** All ledger queries and insertions are strictly scoped by `business_id`.

## 20. Dependencies
- **Platform Foundation:** For UUIDs, multi-tenancy, and offline-first data structures.
- **Financial Documents Foundation:** For generic polymorphic document tracking.
- **Shared Value Objects:** For precise handling of money and currency decimals.

## 21. Out Of Scope
- **Chart of Accounts Management:** Creating and managing the hierarchical account structure (handled by the broader Finance module).
- **Operational Logic:** Defining *when* or *why* to bill a customer or pay a supplier.
- **Payment Execution:** The actual transfer of funds via banking or cash gateways.
