# Financial Reporting Foundation Architecture

## 1. Purpose
The purpose of the Financial Reporting Domain is to provide a strictly read-only analytical layer that generates standardized financial statements and reports from the posted, immutable accounting data managed by the General Ledger and governed by Financial Closing. It transforms raw journal entry data into meaningful, auditable financial intelligence for business stakeholders.

## 2. Scope
The scope of the Financial Reporting Domain encompasses:
- **Trial Balance:** Generation of unadjusted and adjusted trial balances for any given period or date range.
- **General Ledger Reports:** Detailed transaction-level reports per account, showing all posted journal entry lines within a period.
- **Balance Sheet:** Statement of financial position at a specific point in time, reflecting assets, liabilities, and equity.
- **Income Statement:** Statement of profit and loss over a defined period, summarizing revenues and expenses.
- **Cash Flow Statement:** Statement of cash inflows and outflows categorized by operating, investing, and financing activities.
- **Financial Analysis Readiness:** The architecture must support extensibility for ratio analysis, comparative reporting, and trend analysis without requiring structural changes.

## 3. Domain Responsibilities
- **Data Aggregation:** Querying and aggregating posted journal entry data from the General Ledger.
- **Report Compilation:** Assembling aggregated data into standardized financial statement formats.
- **Period Validation:** Ensuring reports respect accounting period boundaries and closed period integrity.
- **Presentation Neutrality:** Producing report data structures that are agnostic to the presentation medium (API, PDF, Excel).
- **Deterministic Output:** Guaranteeing that the same inputs always produce the same report output.

## 4. Domain Boundaries
To preserve its role as a pure analytical layer, Financial Reporting MUST NOT:
- **Create Journal Entries:** This is the exclusive responsibility of the General Ledger.
- **Modify Journal Entries:** No write operations on accounting data.
- **Post Transactions:** Transaction lifecycle management belongs to operational domains.
- **Execute Payments:** Money movement belongs to the Payments Domain.
- **Close Accounting Periods:** Period lifecycle management belongs to Financial Closing.
- **Modify Banking:** Bank account and reconciliation management belongs to Banking.
- **Modify Cash Management:** Cash register operations belong to Cash Management.

**The domain is strictly READ-ONLY.** It consumes data; it never produces or mutates financial records.

## 5. Domain Principles
- **Reports are generated from posted accounting data only:** Draft, pending, or reversed entries are excluded from standard financial reports unless explicitly requested for analytical purposes.
- **Closed periods guarantee reporting integrity:** Reports covering closed periods are guaranteed to be stable and reproducible.
- **Reports are deterministic and reproducible:** Given the same parameters (business, period, date range), the same report will always yield the same results.
- **Reporting is tenant-isolated:** All report queries and outputs are strictly scoped by `business_id`.
- **No side effects:** Report generation never triggers writes, events, or state changes in any domain.

## 6. Aggregate Roots
The expected Aggregate Root for this domain is:
- **FinancialReport:** The primary entity representing a generated report instance, encapsulating its type, parameters, and computed results.

*(Note: Exact internal entities, value objects, and report line structures will be defined in subsequent architectural documents.)*

## 7. Reporting Principles
- **Standardization:** All financial statements follow internationally recognized accounting standards (IFRS/GAAP structure).
- **Parameterization:** Reports accept standardized parameters: `business_id`, `fiscal_year_id`, `period_range`, `as_of_date`, and `currency_id`.
- **Comparative Support:** The architecture must natively support side-by-side period comparisons (e.g., current vs. prior year).
- **Account Classification:** Reports rely on the Chart of Accounts classification hierarchy (account types, groups) defined in the Finance Foundation.
- **Currency Handling:** Reports must respect multi-currency configurations, presenting amounts in the business base currency.

## 8. General Ledger Relationship
- Financial Reporting reads posted `JournalEntry` and `JournalEntryLine` data from the General Ledger.
- It queries aggregated balances (sum of debits, sum of credits) per account for the requested period.
- It never writes to or modifies any GL table.

## 9. Financial Closing Relationship
- Financial Reporting queries the `AccountingPeriod` status from the Financial Closing domain to determine whether a reported period is finalized.
- Reports may visually indicate whether the underlying data is from a closed (finalized) or open (preliminary) period.
- Financial Reporting never initiates or modifies closing operations.

## 10. Finance Relationship
- Financial Reporting relies on the Finance Foundation for the Chart of Accounts structure, account types, and fiscal period definitions.
- It uses `FiscalYear` and `FiscalPeriod` boundaries to scope report date ranges.
- It leverages account classification (Asset, Liability, Equity, Revenue, Expense) to structure balance sheets and income statements.

## 11. Audit Principles
- **Report Generation Logging:** Each report generation may be logged with the requesting user, timestamp, and parameters for audit traceability.
- **Data Integrity:** Reports include metadata indicating whether the underlying periods are closed or open, providing transparency to auditors.
- **No Data Mutation:** The read-only nature inherently preserves audit integrity.

## 12. Security Principles
- **Authorization:** Access to financial reports is restricted to users with appropriate financial viewing privileges.
- **Tenant Isolation:** All report queries are strictly filtered by `business_id`.
- **Data Sensitivity:** Certain reports (e.g., full P&L, balance sheet) may require elevated permissions beyond basic financial access.

## 13. Dependencies
- **General Ledger Domain:** Primary data source for all journal entries and line-level detail.
- **Financial Closing Domain:** For period status verification (open vs. closed).
- **Finance Foundation:** For Chart of Accounts, account types, fiscal years, fiscal periods, and currency definitions.
- **Platform Foundation:** For multi-tenancy, user authentication, and authorization.

## 14. Out Of Scope
- **Budgeting and Forecasting:** Budget management and variance analysis.
- **Tax Reporting:** Tax-specific filings and calculations.
- **Consolidation:** Multi-entity or group-level consolidation.
- **Custom Report Builder:** Ad-hoc user-defined report creation tools.
- **Data Warehousing:** Long-term analytical storage or OLAP cubes.
- **Dashboard Widgets:** Real-time operational dashboards (these consume reports but are a UI concern).
