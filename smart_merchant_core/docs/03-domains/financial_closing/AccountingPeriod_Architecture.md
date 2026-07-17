# AccountingPeriod Architecture

## 1. Purpose
The purpose of the `AccountingPeriod` Aggregate Root is to serve as the definitive gatekeeper for all financial transactions occurring within a specific time boundary. It enforces the temporal integrity of the General Ledger by controlling whether a given fiscal period is open for postings, in the process of closing, permanently closed, or temporarily reopened.

## 2. Responsibilities
- **Manage the accounting period lifecycle:** Oversee the transition of the period through its operational states.
- **Control period opening:** Dictate when a period is initialized and ready to accept transactions.
- **Control period closing:** Orchestrate the locking mechanism that finalizes the period.
- **Control period reopening:** Manage the exceptional process of unlocking a period for authorized adjustments.
- **Protect accounting integrity:** Guarantee that no transactions can alter the financial state of a finalized period.
- **Enforce period locking:** Act as the source of truth queried by the General Ledger before any posting is executed.

## 3. Entity Classification
- **Classification:** Aggregate Root
- **Domain:** Financial Closing

## 4. Relationships
- **Business:** Scopes the accounting period to a specific tenant.
- **Fiscal Year:** Links the period to the broader annual fiscal structure.
- **General Ledger:** The GL continuously polls the `AccountingPeriod` state to authorize or reject `JournalEntry` postings.
- **Closing Operations:** The period may own or reference detailed logs and validation results executed during the closing process.

## 5. Lifecycle
The `AccountingPeriod` aggregate strictly adheres to the following states:
- **Open:** The period is fully operational and accepts new journal entries.
- **Closing:** The period is temporarily halted for new operational postings while final adjusting entries (e.g., depreciation, accruals) are processed and validation checks are run.
- **Closed:** The period is completely locked and finalized. The General Ledger rejects any postings dated within this period.
- **Reopened:** A formerly closed period has been unlocked for authorized corrections.

## 6. Business Rules
- **Only open periods accept new postings:** A period must be `Open` (or `Reopened`) for standard operational transactions to post.
- **Closed periods reject new postings:** The General Ledger enforces this rule based entirely on the `AccountingPeriod` state.
- **Closed periods are immutable:** No data within the period's date range can be altered while the state is `Closed`.
- **Reopening requires authorization:** Reverting a `Closed` period to `Reopened` is a restricted action requiring high privileges and an auditable justification.
- **Closing requires validation of accounting completeness:** A period cannot transition to `Closed` if unbalanced, draft, or pending transactions exist within its date boundary.

## 7. Closing Policy
- The closing operation is atomic and irreversible (except via a formal Reopening procedure).
- Before transitioning to `Closed`, the domain MUST validate that there are no `Draft` Journal Entries in the General Ledger for the given period.
- Operational domains must be queried (via domain events or services) to ensure no pending financial documents remain unposted.
- Upon successful validation, the period state changes to `Closed`, triggering a broadcast event to notify all domains of the lock.

## 8. Reopening Policy
- Reopening is an explicit, exceptional governance action, not a casual undo.
- The system must capture the identity of the authorizing user, the precise timestamp, and a mandatory text justification.
- Reopening transitions the state to `Reopened`, generating a system-wide security audit event.

## 9. Fiscal Period Policy
- `AccountingPeriod` operates in a strict 1-to-1 conceptual alignment with a static `FiscalPeriod` (defined in the Finance Domain).
- While `FiscalPeriod` defines the immutable dates (start and end), `AccountingPeriod` defines the mutable operational lock state (Open, Closed).

## 10. Security Rules
- Period lifecycle transitions (Closing, Reopening) are restricted to users with elevated financial privileges (e.g., Controller, CFO).
- All queries and state changes are strictly isolated by `business_id`.

## 11. Audit Trail
- The aggregate must permanently record the lifecycle transitions, tracking `opened_at`, `closed_at`, and `reopened_at` timestamps.
- The identifiers of the users responsible for each transition (`opened_by`, `closed_by`, `reopened_by`) must be captured.
- A log of reopening justifications must be maintained.

## 12. Ownership Rules
- The `AccountingPeriod` is the absolute owner of its lifecycle and closing state.
- No external domain (including the General Ledger) can alter the closing state directly; they must request the state change through the Financial Closing application layer.

## 13. Dependencies
- **Platform Foundation:** For UUIDs, multi-tenancy, and security.
- **Finance Foundation:** For static `FiscalPeriod` and `FiscalYear` definitions.
- **General Ledger Domain:** Relies heavily on the `AccountingPeriod` state to enforce posting restrictions.

## 14. Out Of Scope
- **Journal Entry creation:** Creating or storing the actual accounting entries.
- **Payment execution:** Processing supplier or customer payments.
- **Banking operations:** Reconciling bank statements.
- **Cash Management:** Managing physical cash flow.
- **Financial Statement generation:** Aggregating data for income statements or balance sheets.
