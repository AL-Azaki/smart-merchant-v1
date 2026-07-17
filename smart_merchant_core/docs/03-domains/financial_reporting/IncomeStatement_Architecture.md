# Income Statement Architecture

## 1. Purpose
The purpose of the Income Statement (Profit & Loss) architecture is to define the principles for generating a definitive, READ-ONLY summary of a business's financial performance over a specific reporting period. It aggregates revenues and expenses to clearly illustrate how operational activities translate into net profit or loss, providing critical insight into the company's profitability.

## 2. Responsibilities
- **Measure Business Profitability:** Quantify the financial success or failure of operations over a defined timeframe.
- **Summarize Revenues and Expenses:** Categorize and aggregate all income generated and costs incurred.
- **Calculate Gross Profit:** Determine the profit after deducting direct costs (Cost of Goods Sold) from revenue.
- **Calculate Operating Profit:** Determine the profit after deducting operating expenses from gross profit.
- **Calculate Net Profit or Loss:** Provide the final bottom-line figure reflecting all financial activities, including taxes and extraordinary items.
- **Support Executive Financial Analysis:** Serve as the primary tool for budget variance analysis, performance evaluation, and strategic planning.

## 3. Architectural Classification
- **Classification:** Financial Report
- **Characteristics:** It is strictly READ-ONLY. It is NOT an Aggregate Root. It is NOT a transactional entity. It does not possess a mutable lifecycle; it is dynamically generated from immutable source data.

## 4. Data Sources
The Income Statement synthesizes its data conceptually from the following sources:
- **Chart of Accounts:** Defines the taxonomy, ensuring accounts are correctly mapped to Revenue, Cost of Goods Sold (COGS), or Expense categories.
- **Journal Entries:** Provides the transactional posting status and overarching date context.
- **Journal Entry Lines:** Provides the granular debit and credit amounts used to calculate period balances.
- **Accounting Period:** Defines the exact start and end dates encompassing the report's timeframe.
- **Financial Closing:** Provides the state (Open/Closed) of the reporting periods to guarantee data finality.

## 5. Reporting Rules
- **Include Posted Entries Only:** The report must strictly aggregate amounts from Journal Entries that hold a `Posted` status. Drafts are excluded.
- **Period-Specific Presentation:** Unlike the Balance Sheet (which is cumulative), the Income Statement measures activity strictly *within* the selected reporting period's start and end dates.
- **Respect Accounting Period Boundaries:** The report must align with the defined fiscal calendar and respect the lock states of closed periods to guarantee historical accuracy.
- **Include Revenue and Expense Accounts Only:** The report excludes Asset, Liability, and Equity accounts entirely.
- **Group by Classification:** Balances must be aggregated and displayed according to the hierarchical classification defined in the Chart of Accounts.

## 6. Profit Calculation Policy
The architecture dictates the following cascading calculation rules:
- **Revenue:** The sum of all posted income. (Normal Credit balance).
- **Cost of Goods Sold (COGS):** The sum of all direct costs attributable to the production of goods sold. (Normal Debit balance).
- **Gross Profit:** `Total Revenue - Total COGS`.
- **Operating Expenses:** The sum of all indirect costs associated with running the business (e.g., rent, payroll, utilities). (Normal Debit balance).
- **Operating Profit:** `Gross Profit - Total Operating Expenses`.
- **Net Profit / Net Loss:** `Operating Profit + Other Income - Other Expenses - Taxes`. A positive result is a Net Profit; a negative result is a Net Loss.

## 7. Currency Policy
- **Base Currency Aggregation:** To maintain mathematical integrity and consistency with the Balance Sheet, all balances and profit calculations must be aggregated and presented in the system's **Base Currency**.
- **Foreign Currency:** While individual revenue or expense transactions may have occurred in foreign currencies, the Income Statement relies exclusively on the base currency equivalents calculated and stored during the General Ledger posting process.

## 8. Security Rules
- **Tenant Isolation:** All data queries and aggregations must be strictly filtered by the `business_id` to ensure absolute tenant data privacy.
- **Executive Authorization:** Generation and viewing of the Income Statement are restricted to users with high-level financial reporting or executive privileges.

## 9. Audit Principles
- **Data Provenance:** Every aggregated number on the Income Statement must be traceable back to immutable, posted Journal Entry Lines (via the General Ledger Report).
- **Period State Transparency:** The report must clearly indicate the state of the Accounting Period(s) it covers (e.g., Open, Closed). An Income Statement generated for a fully closed fiscal year is considered final and immutable.

## 10. Dependencies
- **General Ledger Domain:** The authoritative source for Journal Entries and Lines.
- **Finance Foundation:** The source for the Chart of Accounts, account classifications (Revenue, COGS, Expense), and base currency definitions.
- **Financial Closing Domain:** The source for Accounting Period statuses and fiscal year boundaries.

## 11. Out Of Scope
- **Posting Journal Entries:** The Income Statement does not create or post transactions.
- **Editing Journal Entries:** The report cannot alter any underlying data.
- **Financial Closing Operations:** The report does not execute closing operations or zero-out nominal accounts.
- **Payment Processing:** No interaction with AP/AR settlements.
- **Banking Operations:** No interaction with bank feeds or reconciliations.
- **Cash Management Operations:** No interaction with POS cash registers.
