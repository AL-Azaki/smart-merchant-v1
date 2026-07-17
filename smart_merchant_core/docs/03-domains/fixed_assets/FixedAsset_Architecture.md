# FixedAsset Architecture

## 1. Purpose
The purpose of the `FixedAsset` Aggregate Root is to serve as the definitive, centralized record for a single long-term tangible or intangible asset owned by the business. It tracks the asset's complete lifecycle from initial acquisition to final disposal, safeguarding its valuation, location, and depreciation configuration.

## 2. Responsibilities
- **Represent a Capital Asset:** Act as the digital twin of a physical or intangible asset.
- **Maintain the Complete Lifecycle:** Manage the asset's state transitions (e.g., Draft to Active to Disposed).
- **Store Acquisition Information:** Maintain the immutable record of the asset's original cost, acquisition date, and vendor details.
- **Define Depreciation Configuration:** Store the rules (method, useful life, residual value) governing how the asset's value decreases over time.
- **Support Operational Readiness:** Enable workflows for asset transfers (location/branch changes), impairment, and disposal.
- **Serve as the Aggregate Root:** Control and encapsulate all internal entities or value objects related to the specific asset within the Fixed Assets Domain.

## 3. Entity Classification
- **Classification:** Aggregate Root
- **Domain:** Fixed Assets

## 4. Relationships
- **Business:** The asset strictly belongs to a single business (tenant isolation).
- **Branch:** The asset may be physically located at or assigned to a specific branch.
- **Asset Category:** The asset belongs to a defined category (e.g., Vehicles, IT Equipment) which dictates its default accounting rules.
- **Currency:** The asset's acquisition cost and subsequent valuations are defined in a specific currency (typically the base currency).
- **Responsible User:** The asset may be assigned to a specific employee or user responsible for its custody.

## 5. Lifecycle
The `FixedAsset` aggregate adheres to the following states:
- **Draft:** The asset record is incomplete or pending financial authorization. It has no accounting impact.
- **Active:** The asset is capitalized and in service, but may not have started its depreciation schedule yet.
- **Depreciating:** The asset is actively undergoing periodic depreciation calculations.
- **Fully Depreciated:** The asset's net book value has reached its predefined residual value. It remains in service but does not generate further depreciation expense.
- **Disposed:** The asset is no longer in service due to sale, scrapping, or loss. Its value has been removed from the balance sheet.

## 6. Business Rules
- **Unique Identification:** Every asset must possess a unique system identifier and should ideally possess a unique physical asset tag.
- **Tenant Integrity:** Every asset belongs strictly to one business.
- **Acquisition Immutability:** Once an asset transitions from `Draft` to `Active` (capitalized), its original acquisition cost cannot be directly modified. Adjustments must be handled via specific revaluation or impairment events.
- **Depreciation Prerequisites:** A complete depreciation configuration (method, useful life, residual value) must exist before an asset can transition to the `Depreciating` state.
- **Disposal Prevention:** An asset cannot be disposed of while it is still in `Draft` status.

## 7. Acquisition Policy
- Acquisition represents the capitalization of the asset.
- Transitioning to `Active` implies the asset is placed in service.
- The acquisition process must eventually integrate with the General Ledger (via Domain Services) to ensure the asset's cost is recorded on the balance sheet, but the Aggregate Root itself only tracks the fact and date of acquisition.

## 8. Depreciation Policy
- **Useful Life:** The duration (in months or years) over which the asset is expected to be economically useful.
- **Residual Value:** The estimated salvage value of the asset at the end of its useful life. The asset's Net Book Value cannot fall below this amount.
- **Depreciation Method:** The algorithm (e.g., Straight-Line, Double Declining Balance) assigned to calculate periodic depreciation.
- **Start Date:** Depreciation begins on the asset's explicitly defined depreciation start date, which may differ from the acquisition date.

## 9. Disposal Policy
- Disposal represents the end of the asset's financial lifecycle.
- Disposal requires recording the disposal date, reason, and any proceeds received.
- The state permanently transitions to `Disposed`.
- Disposal requires calculating depreciation up to the disposal date before removing the asset from the books.

## 10. Currency Policy
- The asset's valuation (Acquisition Cost, Accumulated Depreciation, Net Book Value) is stored and calculated in the business's **Base Currency** to ensure seamless integration with the General Ledger.

## 11. Security Rules
- **Authorization:** Only authorized roles (e.g., Asset Manager) may create, activate, or dispose of assets.
- **Tenant Isolation:** All operations on the Aggregate Root are strictly isolated by `business_id`.

## 12. Audit Trail
- The `FixedAsset` must track the `user_id` and timestamp for creation and all subsequent lifecycle transitions (e.g., `activated_by`, `disposed_by`).
- Changes to critical attributes (like location or responsible user) should generate an audit log.

## 13. Ownership Rules
- The `FixedAsset` Aggregate Root owns its internal state, lifecycle, and depreciation configuration.
- It strictly enforces invariants (e.g., preventing disposal of draft assets).

## 14. Dependencies
- **Platform Foundation:** For UUIDs and multi-tenancy.
- **Finance Foundation:** For currency and branch definitions.
- **Fixed Assets Category Architecture:** (To be defined) for default accounting mappings.

## 15. Out Of Scope
- **Journal Entry Creation:** The aggregate does not create journal entries.
- **Payment Execution:** The aggregate does not pay for the asset.
- **Banking Operations:** The aggregate does not interact with banks.
- **Cash Management:** The aggregate does not handle cash.
- **Financial Reporting:** The aggregate does not generate the balance sheet.
