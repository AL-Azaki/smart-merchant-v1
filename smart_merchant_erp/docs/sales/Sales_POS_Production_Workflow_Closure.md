# Sales / POS Production Workflow Closure

## Overview
This document summarizes the completion of the Sales / POS Production Workflow phase. The goal was to inspect both the React UI reference and the Flutter ERP codebase, preserve existing architecture, and complete the Sales/POS presentation workflow using real local ERP data and application UseCases.

## Actions Taken
1. **Removed UI Mocks & Hardcodes**
   - Replaced hardcoded `1500 YER` and `0.0` prices with real product unit prices.
   - Removed hardcoded `INV-2026-0005` in POS View, now displaying dynamic invoice status.
   - Removed hardcoded `'INV-001'` from Receipt Printing and WhatsApp Sharing, ensuring they use the actual persisted invoice number.
   - Removed mock customers from the Customer Selection Modal.

2. **Integrated Real Data Context**
   - **Products & Prices:** Created `PosProductsNotifier` (`product_unit_provider.dart`) to stream active products and resolve their base product unit selling price.
   - **Customers:** Created `CustomersNotifier` (`customer_provider.dart`) to stream real SQLite customers. Connected `CustomerAddModal` to `CustomerApplicationService` to persist new customers through the architecture stack (UI -> Riverpod -> UseCase -> DAO -> SQLite) without generating fake `temp_` IDs.
   - **Warehouse & Session:** Connected POS cart submission to the session's current `branchId` (or default warehouse fallback).

3. **Resolved Sales Workflow**
   - Corrected the payment modal to use actual invoice ID generated from `CompleteSaleUseCase`.
   - Maintained the strict Riverpod Architecture: `pos_view` -> `pos_provider` -> `complete_sale_usecase` -> `sales_repository`.

## Identified Capability Gaps
During the architectural audit and implementation, several intentional limitations were respected to prevent faking data. The following gaps must be addressed in future sprints to complete the ERP capabilities:

### 1. SALES CAPABILITY GAP — PERSISTENT DRAFT / SUSPENDED SALE
- **Issue:** The architecture has no `held_invoices` or `draft_sales` persistence table, no DraftSale repository capability, and no `SaveDraftInvoiceUseCase`.
- **Status:** The POS retains the cart in memory within the Riverpod state, but persistent suspension across sessions/restarts is missing. 
- **Recommendation:** Implement a draft persistence mechanism at the DAO/Repository level.

### 2. SALES CAPABILITY GAP — PRODUCT TAX RESOLUTION
- **Issue:** `product_taxes` and `taxes` tables exist, but there is no direct query exposing a product's resolved tax rate to the UI layer. 
- **Status:** We refrained from silently applying 15% VAT. 
- **Recommendation:** Implement a tax resolution mechanism in `CatalogRepository` to return `ProductWithTax` or allow dynamic tax calculation in `SalesCalculator`.

### 3. SALES CAPABILITY GAP — TREASURY PAYMENT INTEGRATION (Cash/Card/Transfer)
- **Issue:** `CompleteSaleUseCase` marks invoices as `Paid` (if not a credit sale), but it **does not** create a Treasury Payment (`ReceivePaymentUseCase`). It debits accounts directly without creating a Treasury Receipt. 
- **Status:** The UI triggers the sale execution properly, but financial settlement for non-credit sales bypasses Treasury orchestration.
- **Recommendation:** Refactor `CompleteSaleUseCase` to coordinate with Treasury boundaries for accurate Cash/Bank ledger entries.

## Verification
- Code successfully builds with `build_runner`.
- POS UI successfully reacts to local database state.
- Adding a customer persists to SQLite and immediately reflects in the dropdown.
- Selling an item calls `CompleteSaleUseCase` and opens the success dialog with the generated invoice ID.

## Next Steps
- Address the capability gaps at the application and data layer levels.
- Perform deeper integration testing of the POS workflow with the Treasury and Inventory boundaries.
