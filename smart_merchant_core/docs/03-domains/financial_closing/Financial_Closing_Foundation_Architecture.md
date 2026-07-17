# Financial Closing Foundation Architecture

## 1. Purpose
The purpose of the Financial Closing Domain is to manage the strict progression of accounting periods, ensuring the integrity and immutability of financial data over time. It governs the locking of historical data to prevent unauthorized adjustments to finalized periods, ensuring compliance with auditing standards and preparing the foundation for accurate financial reporting.

## 2. Scope
The scope of the Financial Closing Domain encompasses:
- **Accounting Period Management:** Controlling the operational state of fiscal periods.
- **Period Closing:** The systematic process of locking a period against new or modified accounting entries.
- **Period Reopening:** The highly restricted process of unlocking a previously closed period for authorized corrections.
- **Fiscal Year Closing:** The specialized process of finalizing an entire fiscal year.
- **Carry Forward Readiness:** Ensuring the ledger is validated and prepared for balance carry-forward operations into the next period or year.
- **Accounting Locking:** Enforcing a hard lock on the General Ledger based on the period state.
- **Financial Integrity:** Validating that no pending, draft, or unbalanced transactions exist before a period is allowed to close.

## 3. Domain Responsibilities
- **Lifecycle Management:** Dictating and transitioning the state of an accounting period.
- **Integrity Validation:** Enforcing prerequisite checks (e.g., no pending drafts) prior to closing.
- **General Ledger Enforcement:** Notifying and integrating with the GL to enforce posting locks based on period states.
- **Audit Traceability:** Maintaining a permanent record of exactly who, when, and why a period was closed or reopened.

## 4. Domain Boundaries
To preserve its specific role as the temporal governance layer, Financial Closing MUST NOT:
- **Create Journal Entries:** This is the exclusive responsibility of the General Ledger.
- **Modify Posted Journal Entries:** Data manipulation is strictly prohibited.
- **Execute Payments:** Money movement belongs to the Payments Domain.
- **Manage Cash Registers:** Belongs to Cash Management.
- **Manage Bank Accounts:** Belongs to Banking.
- **Manage Customer Receivables:** Belongs to Accounts Receivable.
- **Manage Supplier Payables:** Belongs to Accounts Payable.
- **Generate Financial Statements:** Reporting belongs to the broader Finance/Reporting infrastructure.

## 5. Domain Principles
- **Closed Periods are Immutable:** A closed period acts as an absolute lock; no operational or financial transactions can be posted within its date range.
- **Restricted Reopening:** Only authorized, highly privileged users may reopen a closed period, and they must provide an auditable justification.
- **Completeness Verification:** Closing validates accounting completeness; a period cannot be closed if incomplete or draft transactions remain.
- **Event-Driven Synchronization:** Closing or reopening a period broadcasts domain events to synchronize the General Ledger and other sub-domains.
- **Tenant Isolation:** All closing operations and period states are strictly isolated by `business_id`.

## 6. Aggregate Roots
The expected Aggregate Root for this domain is:
- **AccountingPeriod:** The primary entity representing the lockable time boundary and its operational state for a given tenant.

*(Note: Exact internal entities and relationships will be defined in subsequent architectural documents.)*

## 7. Lifecycle Principles
The `AccountingPeriod` adheres to the following states:
- **Open:** The period accepts new postings and operational transactions.
- **Closing:** An intermediate state where the system runs integrity checks and halts new operational inputs while allowing final adjusting entries.
- **Closed:** The period is permanently locked (unless explicitly reopened). No postings are permitted.
- **Reopened:** A previously closed period that has been temporarily unlocked for authorized corrections.

## 8. Closing Principles
- Closing is a deliberate, atomic state transition.
- The system must verify that all underlying operational documents (invoices, payments) intended for the period are either posted or explicitly deferred.
- The system must verify that all Draft journal entries within the period dates are either posted, deleted, or moved to a future period.
- If validation fails, the closing process is aborted.

## 9. Reopening Principles
- Reopening is an exceptional operation and is treated as a high-risk security event.
- It requires an explicit, recorded reason.
- It immediately generates an audit log and notifies the Financial Controller or equivalent administrative role.
- Once corrections are made, the period must be subjected to the Closing Principles all over again.

## 10. General Ledger Relationship
- The General Ledger consults the Financial Closing domain (via the `AccountingPeriod` state) before allowing any `JournalEntry` to post. If the target date falls in a closed period, the GL rejects the post.

## 11. Fiscal Period Relationship
- `AccountingPeriod` is closely mapped to, but functionally distinct from, the static `FiscalPeriod` defined in the Finance Foundation. While `FiscalPeriod` defines the dates, `AccountingPeriod` defines the operational lock state.

## 12. Finance Relationship
- Financial Closing relies on the broader Finance foundation for configuration, charts of accounts validations, and basic calendar definitions.

## 13. Audit Principles
- **Traceability:** Every state change (Open -> Closed -> Reopened) must record the `user_id` and exact `timestamp`.
- **Justification:** Reopening requires a mandatory `reason` text.
- **Event Logging:** All closing/reopening actions generate immutable system audit events.

## 14. Security Principles
- **Strict Authorization:** Only the highest tier of financial management (e.g., Admin, Controller) holds the permission to change an `AccountingPeriod` state.
- **Tenant Security:** All operations are strictly scoped by `business_id`.

## 15. Dependencies
- **Platform Foundation:** For multi-tenancy, UUIDs, and user authentication.
- **Finance Foundation:** For base `FiscalYear` and `FiscalPeriod` mapping.
- **General Ledger Domain:** For validating that no Draft journals exist prior to closing.

## 16. Out Of Scope
- **Depreciation Calculation:** Fixed asset logic is separate.
- **Tax Filing Generation:** Tax operations are separate.
- **Currency Revaluation:** Revaluation entries are generated by a separate module (though they must be posted before closing).
- **Consolidation:** Multi-company consolidation is handled externally.
