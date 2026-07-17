# ClosingOperation Architecture

## 1. Purpose
The purpose of the `ClosingOperation` is to define the rigorous, sequential architectural process required to safely and securely transition an `AccountingPeriod` from `Open` to `Closed`. It guarantees that all financial prerequisites are met before permanently locking the ledger for a specific period.

## 2. Responsibilities
- **Execute Period Closing:** Orchestrate the actual state transition of the `AccountingPeriod`.
- **Validate Closing Prerequisites:** Ensure no pending, draft, or unbalanced transactions exist that would compromise the finalized period.
- **Lock the Accounting Period:** Enforce the operational lock to prevent further modifications.
- **Coordinate with General Ledger:** Communicate with the GL to verify ledger integrity before proceeding.
- **Publish Closing Events:** Broadcast the successful closure to the rest of the system so dependent modules (e.g., Reporting) can rely on the finalized data.
- **Preserve Accounting Integrity:** Guarantee that the close is atomic and failure-proof.

## 3. Architectural Classification
- **Classification:** Domain Process (NOT an Entity, NOT an Aggregate Root)
- **Domain:** Financial Closing

## 4. Relationships
- **AccountingPeriod:** The primary target of the operation. The operation evaluates and eventually mutates the state of the target period.
- **General Ledger:** The operation depends on the GL to confirm there are no draft entries or imbalances.
- **Fiscal Year:** The operation must respect fiscal year boundaries, particularly when closing the final period of a year (Carry Forward).
- **Audit Log:** The operation mandates generating permanent audit records of its execution, whether successful or failed.

## 5. Lifecycle
The `ClosingOperation` progresses through the following ephemeral execution states:
- **Pending:** The operation has been initiated by an authorized user but execution has not yet started.
- **Validating:** The operation is actively querying other domains (GL, operational domains) to ensure prerequisites are met.
- **Executing:** All validations have passed, and the operation is atomically updating the `AccountingPeriod` state and writing audit logs.
- **Completed:** The period has been successfully closed, and events have been published.
- **Failed:** The operation was aborted due to validation failures or system errors. The period remains in its original state.

## 6. Validation Policy
Before a closing operation can proceed to the `Executing` phase, it MUST validate:
- **No Pending Accounting Validation Failures:** The General Ledger must confirm zero Draft or unposted Journal Entries dated within the period.
- **Period Must Be Open:** The target `AccountingPeriod` must currently be in the `Open` (or `Reopened`) state.
- **User Authorization Required:** The initiating user must possess explicit Financial Controller or Administrator privileges.
- **Sequential Integrity:** Previous accounting periods within the same fiscal year must already be closed (no gap periods).

## 7. Closing Policy
- The actual closing execution (state transition) must be atomic. It must occur within a strict database transaction.
- If the transaction succeeds, the `AccountingPeriod` is permanently set to `Closed`.
- Upon success, the domain must publish a `PeriodClosed` domain event to notify the rest of the enterprise architecture.

## 8. Failure Policy
- If any validation rule fails, the entire operation is immediately aborted.
- **No Partial Closing is Allowed:** A period is either 100% closed or not closed at all.
- A failure must log the exact reason (e.g., "Draft journal entries exist") and revert any temporary state changes. The period remains `Open`.

## 9. Re-execution Policy
- A failed `ClosingOperation` can be re-executed at any time once the underlying issues (e.g., posting draft entries) have been resolved.
- There is no penalty or limit on the number of closing attempts, provided each attempt generates an audit trail of the failure.

## 10. Security Rules
- Initiating a `ClosingOperation` requires the highest level of financial privilege.
- Operations are strictly isolated by `business_id` (Tenant Isolation).

## 11. Audit Trail
- The `ClosingOperation` itself must generate an audit record detailing the `user_id`, the timestamp of initiation, the final status (Completed or Failed), and the failure reason if applicable.
- This audit log is permanently linked to the `AccountingPeriod`.

## 12. Dependencies
- **AccountingPeriod Architecture:** The core aggregate being manipulated.
- **General Ledger Domain:** For validating that no Draft journals exist prior to closing.
- **Finance Foundation:** For overarching fiscal period logic.

## 13. Out Of Scope
- **Journal Entry Creation:** The operation only checks entries; it does not create them.
- **Payment Execution:** Not related to processing actual payments.
- **Banking Operations:** Bank reconciliations should be completed before closing, but the operation itself does not do banking.
- **Cash Management:** Not related to drawer closings.
- **Financial Statements:** The operation secures the data for statements, but generating the statements is a reporting concern.
- **Budgeting:** Managing financial budgets or forecasts.
