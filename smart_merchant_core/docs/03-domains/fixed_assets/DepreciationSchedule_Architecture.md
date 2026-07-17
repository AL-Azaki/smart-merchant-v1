# DepreciationSchedule Architecture

## 1. Purpose
The purpose of the `DepreciationSchedule` entity is to meticulously track and manage the planned and executed depreciation events for a specific Fixed Asset. It breaks down the asset's total depreciable value over its useful life into discrete, manageable periods, providing an auditable timeline of when and how much depreciation should be or has been recognized.

## 2. Responsibilities
- **Define the Depreciation Plan:** Detail the exact financial allocation (depreciation amount) expected for each specific period over the asset's useful life.
- **Schedule Future Depreciation Periods:** Provide a projected timeline of depreciation events for forecasting and automated processing.
- **Track Depreciation Execution Readiness:** Indicate whether a specific scheduled period is eligible and ready to be posted to the General Ledger.
- **Record Depreciation Lifecycle Status:** Track the progression of each scheduled period from pending to successfully posted or cancelled.
- **Support Auditability of Depreciation History:** Provide an immutable historical record of exactly what was depreciated, when, and the resulting change in the asset's net book value.

## 3. Entity Classification
- **Classification:** Child Entity
- **Ownership:** Owned exclusively by the `FixedAsset` Aggregate Root. It has no independent existence outside of its parent asset.

## 4. Relationships
- **FixedAsset:** A strict child-to-parent relationship. A `DepreciationSchedule` record inherently belongs to exactly one `FixedAsset`.

## 5. Lifecycle
Each `DepreciationSchedule` period adheres to the following states:
- **Pending:** The period is scheduled for the future but is not yet eligible for posting.
- **Ready:** The scheduled date has arrived (or the requisite accounting period is open), making the schedule eligible to be posted.
- **Posted:** The depreciation amount for this schedule has been successfully integrated with the General Ledger and recognized in the financials.
- **Cancelled:** The schedule has been invalidated (e.g., due to an asset disposal, impairment, or a change in depreciation method) and will not be posted.

## 6. Business Rules
- **Exclusive Belonging:** Every schedule record must belong to exactly one `FixedAsset`.
- **Parent Dependency:** A schedule cannot exist or be created without a valid, corresponding parent asset.
- **Immutability of Posted Records:** Once a schedule is marked as `Posted`, its financial values (depreciation amount, accumulated total) and dates are strictly immutable.
- **Cancellation Finality:** A schedule marked as `Cancelled` is permanently locked and can never transition to `Ready` or `Posted`.
- **Configuration Adherence:** The sum of all planned and posted depreciation schedules for an asset must perfectly align with the parent asset's configured depreciable base and residual value.

## 7. Depreciation Period Policy
- **Depreciation Start:** Schedules must respect the `depreciation_start_date` defined on the parent asset, which dictates the first period eligible for depreciation.
- **Depreciation End:** The schedule generation must logically conclude when the asset reaches the end of its useful life or its defined residual value.
- **Scheduled Posting Date:** Each schedule record must define the specific date or accounting period when it is intended to be executed.
- **Remaining Depreciation Periods:** If an asset's valuation changes (e.g., impairment), the unposted (`Pending` or `Ready`) schedules must be recalculated or cancelled and replaced to reflect the new remaining depreciable base.

## 8. Posting Readiness Policy
- A schedule transitions to `Ready` only when its scheduled date falls within the current operational timeframe.
- The architecture merely tracks readiness and status. It **MUST NOT** perform the actual posting or create journal entries itself.
- A schedule is only eligible for the `Posted` status after receiving a confirmed, successful acknowledgment from the General Ledger integration layer indicating the corresponding journal entry has been created and committed.

## 9. Security Rules
- **Tenant Isolation:** Because it is a child entity, its tenant isolation is implicitly derived from and enforced by the parent `FixedAsset`'s `business_id`.
- **Authorization via Aggregate:** Direct mutation of the schedule is prohibited. All state changes (e.g., marking as posted or cancelled) must be orchestrated through the `FixedAsset` Aggregate Root, which enforces authorization.

## 10. Audit Trail
- A schedule must track timestamps for when it was marked as `Posted` or `Cancelled`.
- The identity (`user_id` or system process) that triggered the state change to `Posted` or `Cancelled` must be permanently recorded to support financial compliance.

## 11. Ownership Rules
- The `DepreciationSchedule` is an internal detail of the `FixedAsset`.
- External domains and services must query or interact with schedules exclusively through the API boundary of the `FixedAsset` Aggregate Root.

## 12. Dependencies
- **FixedAsset Architecture:** Relies on the parent aggregate for existence, configuration, and security context.
- **Financial Closing Domain:** Conceptually dependent on Accounting Periods to determine `Ready` state eligibility.

## 13. Out Of Scope
- **Journal Entry Creation:** The schedule does not create accounting journals.
- **General Ledger Posting:** It does not integrate directly with the GL; it relies on domain services to handle the payload.
- **Payment Execution:** Not relevant.
- **Banking Operations:** Not relevant.
- **Cash Management:** Not relevant.
- **Financial Reporting:** It provides data, but does not build reports.
