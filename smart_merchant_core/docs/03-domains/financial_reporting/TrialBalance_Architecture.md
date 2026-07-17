# Trial Balance Architecture

## 1. Purpose
The purpose of the Trial Balance architecture is to define the principles for generating a definitive, READ-ONLY summary of all ledger account balances for a specific period or date range. It serves as the foundational report for verifying the mathematical accuracy of the double-entry accounting system before generating formal financial statements.

## 2. Responsibilities
- **Summarize posted accounting balances:** Aggregate all transaction lines to present a net balance for each account.
- **Display debit and credit totals by account:** Show the gross debit and credit movements, or net balances, organized by the Chart of Accounts.
- **Verify accounting balance integrity:** Provide a macro-level view to ensure that the fundamental accounting equation holds true.
- **Support downstream financial statements:** Act as the verified data source for generating the Balance Sheet and Income Statement.

## 3. Architectural Classification
- **Classification:** Financial Report
- **Characteristics:** Strictly READ-ONLY. It is NOT an Aggregate Root. It is NOT a transactional entity. It does not possess a mutable lifecycle.

## 4. Data Sources
The Trial Balance aggregates data conceptually from the following sources:
- **Journal Entries:** The headers providing the posting status, dates, and tenant context.
- **Journal Entry Lines:** The detailed debit and credit amounts linked to specific accounts.
- **Chart of Accounts:** The hierarchical structure defining account types, classifications, and names.
- **Accounting Period:** The temporal boundary defining the scope of the report and its locked/unlocked state.

## 5. Reporting Rules
- **Posted Entries Only:** The report must strictly aggregate amounts from Journal Entries that hold a `Posted` status.
- **Ignore Draft Entries:** Draft, pending, or incomplete entries must be entirely excluded from the standard Trial Balance calculation.
- **Ignore Reversed Entries:** Reversed entries (and their corresponding reversal entries) should net to zero, but strict implementations may exclude them from gross totals to prevent inflating volume.
- **Respect Period Boundaries:** The report must accurately filter entries based on the requested Accounting Period or explicit date range.
- **Point-in-Time Accuracy:** The report represents the exact state of the ledger for the requested parameters at the moment of generation.

## 6. Balance Validation Policy
- **Fundamental Principle:** Total Debit MUST strictly equal Total Credit (`Total Debit = Total Credit`).
- **Validation Failure:** If the aggregated totals do not balance, the report must highlight the discrepancy, indicating a severe architectural failure in the General Ledger's posting engine or data integrity.

## 7. Currency Policy
- **Base Currency Aggregation:** To ensure the Balance Validation Policy holds true, all aggregated totals (Total Debit, Total Credit, and Account Balances) must be calculated and presented in the system's **Base Currency**.
- **Foreign Currency (Informational):** While individual lines may originate in foreign currencies, the Trial Balance relies on the `base_amount` stored during the posting process to guarantee a balanced ledger.

## 8. Security Rules
- **Tenant Isolation:** The report must strictly filter all data sources by `business_id`.
- **Authorization:** Generation and viewing of the Trial Balance are restricted to users with explicit financial reporting privileges.

## 9. Audit Principles
- **Data Provenance:** Every aggregated number on the Trial Balance must be completely traceable back to immutable, posted Journal Entry Lines.
- **Period Status Transparency:** The report should indicate the state of the Accounting Period (e.g., Open, Closed) it covers, allowing auditors to understand if the balances are subject to change.

## 10. Dependencies
- **General Ledger Domain:** The authoritative source for Journal Entries and Lines.
- **Finance Foundation:** The source for the Chart of Accounts and base currency definitions.
- **Financial Closing Domain:** The source for Accounting Period definitions and statuses.

## 11. Out Of Scope
- **Posting Journal Entries:** The Trial Balance does not create or post transactions.
- **Editing Journal Entries:** The report cannot alter any underlying data.
- **Financial Closing:** The report does not execute closing operations.
- **Payment Processing:** No interaction with AP/AR settlements.
- **Banking Operations:** No interaction with bank feeds or reconciliations.
