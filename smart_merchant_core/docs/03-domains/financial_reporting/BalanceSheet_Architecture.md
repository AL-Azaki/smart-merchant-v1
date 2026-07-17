# Balance Sheet Architecture

## 1. Purpose
The purpose of the Balance Sheet architecture is to define the principles for generating a definitive, READ-ONLY statement of the business's financial position at a specific point in time. It provides a structured view of what the business owns (Assets), what it owes (Liabilities), and the residual interest of the owners (Equity), strictly adhering to the fundamental accounting equation.

## 2. Responsibilities
- **Present Financial Position:** Provide an accurate snapshot of the company's accumulated wealth and obligations as of a specific date.
- **Classify Balances:** Automatically categorize aggregated ledger balances into standard classifications (Assets, Liabilities, and Equity).
- **Verify the Accounting Equation:** Architecturally guarantee and visually demonstrate that `Total Assets = Total Liabilities + Total Equity`.
- **Support Executive Analysis:** Provide reliable data for liquidity, solvency, and operational efficiency analysis.
- **Support Statutory Reporting:** Serve as a compliant foundation for external audits and regulatory submissions.

## 3. Architectural Classification
- **Classification:** Financial Report
- **Characteristics:** It is strictly READ-ONLY. It is NOT an Aggregate Root. It is NOT a transactional entity. It does not possess a mutable lifecycle; it is dynamically generated from immutable source data.

## 4. Data Sources
The Balance Sheet synthesizes its data conceptually from the following sources:
- **Chart of Accounts:** Defines the taxonomy, ensuring accounts are correctly mapped to Asset, Liability, or Equity categories.
- **Journal Entries:** Provides the transactional posting status and overarching date context.
- **Journal Entry Lines:** Provides the granular debit and credit amounts used to calculate net balances.
- **Accounting Period:** Defines the temporal boundaries and lock states to ensure data integrity up to the "As Of" date.
- **Financial Closing:** Provides the logic (e.g., Carry Forward readiness) to correctly calculate historical Retained Earnings.

## 5. Reporting Rules
- **Include Posted Entries Only:** The report must strictly aggregate amounts from Journal Entries that hold a `Posted` status. Drafts are excluded.
- **Point-in-Time Presentation:** The report is generated "As Of" a specific date, summarizing all financial history from the inception of the business up to that date.
- **Respect Accounting Period Boundaries:** The report must align with the defined fiscal calendar and respect the lock states of closed periods to guarantee historical accuracy.
- **Dynamic Retained Earnings:** The report must dynamically compute Current Year Net Income (Revenue minus Expenses) and add it to historical Retained Earnings, ensuring the balance sheet balances without requiring manual closing entries mid-year.
- **Group by Classification:** Balances must be aggregated and displayed according to the hierarchical classification defined in the Chart of Accounts.

## 6. Account Classification Policy
- **Assets:** Accounts classified as Assets represent economic resources. Their balances are calculated based on a normal Debit balance (Debits - Credits).
- **Liabilities:** Accounts classified as Liabilities represent obligations. Their balances are calculated based on a normal Credit balance (Credits - Debits).
- **Equity:** Accounts classified as Equity represent owner's interest. Their balances are calculated based on a normal Credit balance (Credits - Debits).
- **Classification Source of Truth:** The determination of an account's classification belongs entirely to the `Finance Foundation` (Chart of Accounts). The Financial Reporting domain merely consumes and respects this mapping.

## 7. Currency Policy
- **Base Currency Aggregation:** To maintain the integrity of the fundamental accounting equation, all balances must be calculated, aggregated, and presented in the system's **Base Currency**.
- **Foreign Currency:** While individual transactions may have occurred in foreign currencies, the Balance Sheet relies exclusively on the base currency equivalents calculated and stored during the General Ledger posting process.

## 8. Security Rules
- **Tenant Isolation:** All data queries and aggregations must be strictly filtered by the `business_id` to ensure absolute tenant data privacy.
- **Executive Authorization:** Generation and viewing of the Balance Sheet are restricted to users with high-level financial reporting or executive privileges.

## 9. Audit Principles
- **Data Provenance:** Every aggregated number on the Balance Sheet must be traceable back to immutable, posted Journal Entry Lines (via the General Ledger Report).
- **Period State Transparency:** The report must indicate the state of the Accounting Period(s) it covers (e.g., Open, Closed). A Balance Sheet generated for a closed period is considered final and immutable.

## 10. Dependencies
- **General Ledger Domain:** The authoritative source for Journal Entries and Lines.
- **Finance Foundation:** The source for the Chart of Accounts, account classifications, and base currency definitions.
- **Financial Closing Domain:** The source for Accounting Period statuses and fiscal year boundaries.

## 11. Out Of Scope
- **Posting Journal Entries:** The Balance Sheet does not create or post transactions.
- **Editing Journal Entries:** The report cannot alter any underlying data.
- **Financial Closing Operations:** The report does not execute closing operations or generate carry-forward entries.
- **Payment Processing:** No interaction with AP/AR settlements.
- **Banking Operations:** No interaction with bank feeds or reconciliations.
- **Cash Management Operations:** No interaction with POS cash registers.
