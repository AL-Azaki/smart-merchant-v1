# Fixed Assets Foundation Architecture

## 1. Purpose
The purpose of the Fixed Assets Domain is to manage the complete lifecycle of a business's long-term tangible and intangible assets. It governs the registration, valuation, depreciation, and eventual disposal of assets, ensuring accurate financial representation of capital investments over time in compliance with accounting standards.

## 2. Scope
The scope of the Fixed Assets Domain encompasses:
- **Fixed Asset Registration:** Defining and cataloging assets.
- **Asset Classification:** Grouping assets into standardized categories (e.g., Machinery, Vehicles, Buildings).
- **Asset Acquisition:** Recording the initial capitalization and cost basis of an asset.
- **Depreciation Readiness:** Managing depreciation methods, schedules, and calculations.
- **Asset Disposal Readiness:** Managing the sale, scrapping, or write-off of an asset at the end of its useful life.
- **Asset Transfer Readiness:** Tracking the physical or departmental movement of assets.
- **Asset Impairment Readiness:** Adjusting asset values due to sudden loss of utility or market value.
- **Asset Lifecycle Management:** Controlling the operational state of an asset from draft to disposal.

## 3. Domain Responsibilities
- **Asset Governance:** Maintain the definitive source of truth for all capitalized business assets.
- **Valuation Management:** Track the historical cost, accumulated depreciation, and net book value of every asset.
- **Depreciation Calculation:** Systematically compute periodic depreciation expenses according to established accounting policies (e.g., Straight-Line, Declining Balance).
- **Event Orchestration:** Manage asset-related events (acquisition, depreciation run, disposal) and trigger the corresponding accounting integration requests.
- **Integrity Preservation:** Ensure that the sum of all individual asset book values reconciles with the corresponding Fixed Asset control accounts in the General Ledger.

## 4. Domain Boundaries
To preserve its specific role as an operational and valuation management layer, the Fixed Assets Domain MUST NOT:
- **Create Journal Entries directly:** It must submit `PostingRequestDTO` payloads to the General Ledger.
- **Modify Journal Entries:** No direct manipulation of accounting ledgers.
- **Execute Payments:** Purchasing an asset or receiving cash from disposal belongs to Purchasing, Accounts Payable, or Accounts Receivable.
- **Manage Bank Accounts:** Belongs to the Banking domain.
- **Manage Cash Registers:** Belongs to Cash Management.
- **Manage Financial Closing:** Period closing belongs to the Financial Closing domain.
- **Generate Financial Reports:** Generating Balance Sheets or Income Statements belongs to Financial Reporting.

## 5. Domain Principles
- **Unique Identity:** Every asset has a unique, immutable system identifier and often a physical tracking code (e.g., barcode/asset tag).
- **Tenant Isolation:** Every asset belongs strictly to one business; multi-tenant isolation is mandatory.
- **Lifecycle Integrity:** Assets transition through a strict, forward-moving lifecycle.
- **Policy Adherence:** Depreciation calculations must follow approved, auditable accounting policies defined at the asset class or individual level.
- **Immutable History:** Once a financial event (like a depreciation run) is finalized and posted, its historical record on the asset is immutable.
- **Event-Driven Integration:** Financial impacts of asset lifecycle events are communicated to the General Ledger via asynchronous or synchronous posting requests.

## 6. Aggregate Roots
The expected Aggregate Root for this domain is:
- **FixedAsset:** The primary entity representing a single, identifiable capital resource and encapsulating its cost, depreciation rules, and lifecycle state.

*(Note: Exact internal entities, depreciation schedules, and value objects will be defined in subsequent architectural documents.)*

## 7. Lifecycle Principles
The `FixedAsset` adheres to the following states:
- **Draft:** The asset record is being created but is not yet capitalized or financially recognized.
- **Active:** The asset is capitalized and in use, though it may not have started depreciating yet.
- **Depreciating:** The asset is currently subject to periodic depreciation calculations.
- **Fully Depreciated:** The asset has reached the end of its useful life or its salvage value; no further depreciation is calculated, but it remains in possession.
- **Disposed:** The asset has been sold, scrapped, or otherwise removed from the business's possession and balance sheet.

## 8. Depreciation Principles
- Depreciation is the systematic allocation of an asset's depreciable amount over its useful life.
- The domain must support standard methods (e.g., Straight-Line).
- Depreciation calculations are executed periodically (usually monthly) based on the asset's in-service date.
- Running depreciation generates a posting request to debit Depreciation Expense and credit Accumulated Depreciation.
- Depreciation cannot reduce an asset's net book value below its defined salvage/residual value.

## 9. Disposal Principles
- Disposal represents the definitive end of the asset's active lifecycle.
- Disposing of an asset requires calculating its final net book value up to the date of disposal.
- The disposal process must generate a posting request to remove the asset's historical cost and accumulated depreciation from the balance sheet, recognizing any resulting gain or loss on sale/disposal.

## 10. General Ledger Relationship
- Fixed Assets acts as a subsidiary ledger to the General Ledger.
- It translates asset lifecycle events (Acquisition, Depreciation, Impairment, Disposal) into standard `PostingRequestDTO` payloads.
- The General Ledger evaluates these requests, creates the actual `JournalEntry` records, and updates account balances.
- The total Net Book Value in this domain must perpetually reconcile with the General Ledger control accounts.

## 11. Finance Relationship
- Fixed Assets relies on the Finance Foundation for shared definitions, specifically:
  - Chart of Accounts (to map asset classes to specific Asset, Accumulated Depreciation, and Expense accounts).
  - Currency definitions.
  - Cost Centers (if depreciation expense is allocated to specific departments).

## 12. Audit Principles
- **Traceability:** Every change to an asset's valuation (cost adjustments, depreciation runs) must maintain an immutable audit log linking back to the user and timestamp.
- **Reconciliation:** The architecture must natively support reporting that allows auditors to reconcile the asset register against the GL control accounts.

## 13. Security Principles
- **Strict Authorization:** Modifying asset values, changing depreciation methods, or executing disposals requires elevated financial privileges (e.g., Asset Manager, Financial Controller).
- **Tenant Security:** All operations, queries, and reports are strictly scoped by `business_id`.

## 14. Dependencies
- **Platform Foundation:** For UUIDs, multi-tenancy, and user authentication.
- **Finance Foundation:** For Chart of Accounts, currencies, and `PostingRequestDTO` structures.
- **General Ledger Domain:** For processing the actual financial impact of asset operations.

## 15. Out Of Scope
- **Inventory Management:** Fixed Assets are not intended for sale in the ordinary course of business; they are distinct from Inventory.
- **Procurement Workflows:** The actual Purchase Order and receipt process belongs to Purchasing. Fixed Assets picks up the capitalized cost after receipt.
- **Maintenance Management:** Detailed tracking of work orders, repairs, or physical maintenance schedules (CMMS functionality) is a separate operational concern.
