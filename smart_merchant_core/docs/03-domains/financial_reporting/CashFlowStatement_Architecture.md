# Cash Flow Statement Architecture

## 1. Purpose
The purpose of the Cash Flow Statement architecture is to define the principles for generating a definitive, READ-ONLY report that summarizes the amount of cash and cash equivalents entering and leaving the company. It provides critical insights into a company's liquidity, solvency, and its ability to generate cash to fund operations, settle debts, and distribute dividends.

## 2. Responsibilities
- **Present Cash Inflows and Outflows:** Accurately track all money moving into and out of the business during a specific timeframe.
- **Measure Liquidity:** Provide a clear picture of the actual cash available to the business, separate from non-cash accounting profits.
- **Classify Cash Movements by Activity:** Categorize cash flows into standard financial groupings (Operating, Investing, Financing) to analyze the source and use of funds.
- **Support Executive Financial Analysis:** Enable management to evaluate the short-term viability and long-term financial health of the business.
- **Support Statutory Financial Reporting:** Serve as a core component of the standard financial reporting package required for external audits and compliance.

## 3. Architectural Classification
- **Classification:** Financial Report
- **Characteristics:** It is strictly READ-ONLY. It is NOT an Aggregate Root. It is NOT a transactional entity. It does not possess a mutable lifecycle; it is dynamically generated from immutable source data.

## 4. Data Sources
The Cash Flow Statement synthesizes its data conceptually from the following sources:
- **Cash Registers:** Defines the physical points of cash collection/disbursement (from the Cash Management domain).
- **Bank Accounts:** Defines the electronic repositories of funds (from the Banking domain).
- **Chart of Accounts:** Defines the taxonomy, identifying which accounts are classified as Cash/Cash Equivalents and categorizing other accounts for the indirect or direct cash flow method.
- **Journal Entries:** Provides the transactional posting status and overarching date context.
- **Journal Entry Lines:** Provides the granular debit and credit amounts used to calculate cash movements.
- **Accounting Period:** Defines the exact start and end dates encompassing the report's timeframe.
- **Financial Closing:** Provides the state (Open/Closed) of the reporting periods to guarantee data finality.

## 5. Reporting Rules
- **Include Posted Entries Only:** The report must strictly aggregate amounts from Journal Entries that hold a `Posted` status. Drafts are excluded.
- **Include Only Cash-Related Movements:** The report isolates transactions that affect accounts explicitly classified as Cash or Cash Equivalents in the Chart of Accounts.
- **Period-Specific Presentation:** The report measures cash activity strictly *within* the selected reporting period's start and end dates.
- **Respect Accounting Period Boundaries:** The report must align with the defined fiscal calendar and respect the lock states of closed periods.

## 6. Cash Flow Classification Policy
The architecture mandates that all identified cash movements (or adjustments, if using the indirect method) be grouped into three standard categories:
- **Operating Activities:** Cash flows resulting from the primary revenue-generating activities of the business (e.g., receipts from sales, payments to suppliers for inventory, payroll, taxes).
- **Investing Activities:** Cash flows resulting from the acquisition and disposal of long-term assets and other investments not included in cash equivalents (e.g., purchasing equipment, selling property).
- **Financing Activities:** Cash flows resulting from activities that alter the equity capital and borrowing structure of the enterprise (e.g., issuing shares, taking a bank loan, paying dividends, repaying principal).

## 7. Cash Balance Policy
The architecture dictates the following reconciliation flow:
- **Opening Cash Balance:** The absolute sum of all Cash and Cash Equivalent accounts as of the exact start date of the reporting period.
- **Net Cash Flow:** The algebraic sum of Net Cash from Operating Activities, Net Cash from Investing Activities, and Net Cash from Financing Activities.
- **Closing Cash Balance:** `Opening Cash Balance + Net Cash Flow`. 
- **Balance Sheet Reconciliation:** The computed Closing Cash Balance MUST perfectly equal the total of Cash and Cash Equivalent accounts presented on the Balance Sheet for the identical "As Of" date.

## 8. Currency Policy
- **Base Currency Aggregation:** To maintain mathematical integrity and consistency with the Balance Sheet and Income Statement, all cash flows and balances must be aggregated and presented in the system's **Base Currency**.
- **Foreign Exchange Impacts:** Unrealized gains/losses from foreign currency translation on cash balances must be handled appropriately (often presented as a separate reconciling line item at the bottom of the statement) to ensure the closing cash balance reconciles perfectly with the base currency GL balances.

## 9. Security Rules
- **Tenant Isolation:** All data queries and aggregations must be strictly filtered by the `business_id` to ensure absolute tenant data privacy.
- **Executive Authorization:** Generation and viewing of the Cash Flow Statement are restricted to users with high-level financial reporting or executive privileges.

## 10. Audit Principles
- **Data Provenance:** Every aggregated number on the Cash Flow Statement must be traceable back to immutable, posted Journal Entry Lines.
- **Period State Transparency:** The report must clearly indicate the state of the Accounting Period(s) it covers (e.g., Open, Closed). A Cash Flow Statement generated for a fully closed fiscal year is considered final and immutable.

## 11. Dependencies
- **General Ledger Domain:** The authoritative source for Journal Entries and Lines.
- **Finance Foundation:** The source for the Chart of Accounts, account classifications, and base currency definitions.
- **Financial Closing Domain:** The source for Accounting Period statuses and fiscal year boundaries.
- **Cash Management Domain:** Source of truth for physical cash register definitions.
- **Banking Domain:** Source of truth for bank account definitions.

## 12. Out Of Scope
- **Posting Journal Entries:** The Cash Flow Statement does not create or post transactions.
- **Editing Journal Entries:** The report cannot alter any underlying data.
- **Financial Closing Operations:** The report does not execute closing operations.
- **Payment Processing:** The report does not initiate or process AP/AR settlements.
- **Banking Operations:** The report does not perform bank reconciliations or initiate transfers.
- **Cash Management Operations:** The report does not open/close cash registers.
