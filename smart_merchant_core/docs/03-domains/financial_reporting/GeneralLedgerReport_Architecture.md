# General Ledger Report Architecture

## 1. Purpose
The purpose of the General Ledger Report architecture is to define the principles for generating a detailed, chronological, READ-ONLY log of all financial transactions affecting specific ledger accounts. It is the primary instrument for deep-dive financial investigations, reconciliations, and auditing, bridging the gap between high-level summaries (like the Trial Balance) and individual operational transactions.

## 2. Responsibilities
- **Display detailed account movements:** Show every individual debit and credit posting that affects a specific account within the requested period.
- **Present chronological journal activity:** Order all transactions strictly by their posting date to reconstruct the exact sequence of financial events.
- **Calculate running balances:** Compute and display the cumulative balance of the account after every single transaction line.
- **Support auditing and reconciliation:** Provide the granular evidence required by auditors to verify account totals against operational source documents.
- **Support financial investigations:** Enable users to trace anomalies by viewing the exact metadata (e.g., descriptions, source references) of every entry.

## 3. Architectural Classification
- **Classification:** Financial Report
- **Characteristics:** It is strictly READ-ONLY. It is NOT an Aggregate Root. It is NOT a transactional entity. It does not store state; it dynamically computes it.

## 4. Data Sources
The General Ledger Report synthesizes its data from the following immutable sources:
- **Chart of Accounts:** Provides account definitions, classifications (Asset, Liability, etc.), and normal balance expectations (Debit or Credit).
- **Journal Entries:** Provides the transactional header context (date, status, overarching description).
- **Journal Entry Lines:** Provides the granular financial movements (debit amount, credit amount, line-level description, currency).
- **Accounting Period:** Provides the temporal boundaries that scope the report's date range.

## 5. Reporting Rules
- **Include Posted Entries Only:** Only `JournalEntry` records with a `Posted` status are eligible for inclusion.
- **Exclude Draft Entries:** `Draft` or pending entries must be strictly excluded to prevent reporting on uncommitted financial data.
- **Sort Chronologically:** Transactions must be ordered by `posting_date` (and sequentially by creation time or ID if dates are identical) to ensure a mathematically correct running balance.
- **Display Opening Balance:** The report must always calculate and display the opening balance as of the exact start date of the requested period.
- **Display Running Balance:** A continuous balance must be calculated and displayed per transaction line.
- **Display Closing Balance:** The final computed balance at the end of the requested period must be explicitly stated.
- **Respect Accounting Period Boundaries:** The report must accurately restrict the detailed line items to those falling within the requested period(s).

## 6. Balance Calculation Policy
- **Opening Balance Calculation:**
  - For **Balance Sheet Accounts** (Assets, Liabilities, Equity): The opening balance is the sum of all posted activity from the inception of the business up to, but not including, the start date of the report.
  - For **Income Statement Accounts** (Revenue, Expenses): The opening balance is typically the sum of all posted activity from the start of the current *Fiscal Year* up to the report start date (reflecting year-to-date accumulation before the period).
- **Running Balance Calculation:** The running balance is dynamically computed line-by-line. The mathematical operation (addition or subtraction) depends on the account's *Normal Balance* (e.g., a Debit increases an Asset's running balance, but decreases a Liability's running balance).
- **Closing Balance Calculation:** The final running balance after the last chronological transaction in the period.

## 7. Currency Policy
- **Base Currency Dominance:** The Opening Balance, Running Balance, and Closing Balance must be exclusively calculated and presented in the system's **Base Currency** to ensure mathematical integrity.
- **Transactional Currency:** The report should display the original foreign currency amounts and exchange rates on a per-line basis for informational and reconciliation purposes, but the continuous balance relies strictly on the converted base amount.

## 8. Security Rules
- **Tenant Isolation:** All underlying data queries must be strictly filtered by the requesting user's `business_id`.
- **Authorization Enforcement:** Access to this granular transaction history requires high-level financial reporting permissions, as it exposes detailed operational data.

## 9. Audit Principles
- **Absolute Traceability:** Every line on the report must maintain a direct, visible reference (e.g., `journal_number`) to the immutable Journal Entry that produced it.
- **Period State Transparency:** The report must indicate whether the underlying Accounting Period is Open, Closing, Closed, or Reopened, informing the auditor of the data's finality.

## 10. Dependencies
- **General Ledger Domain:** The authoritative repository of Journal Entries and Lines.
- **Finance Foundation:** Defines the Chart of Accounts, account classifications (for Opening Balance rules), and base currency.
- **Financial Closing Domain:** Provides the structure for Accounting Periods.

## 11. Out Of Scope
- **Posting Journal Entries:** The report cannot create or commit transactions.
- **Editing Journal Entries:** Data cannot be mutated through the reporting interface.
- **Financial Closing:** The report does not lock or unlock periods.
- **Payment Processing:** The report does not initiate supplier payments or customer receipts.
- **Banking Operations:** The report does not perform bank reconciliations, though it provides data for them.
