# SQLite Enums Specification
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md` & `SQLite_Phase_01` to `SQLite_Phase_10` documents
**Date:** 2026-07-18

---

## Architectural & Governance Rules

> [!IMPORTANT]
> **Frozen Architecture & Explicit Extraction Rule:**
> تم استخراج جميع الـ **Enumerations (Enums)** الموثقة أدناه حصرياً من قيود التحقق الرسمية (`CHECK Constraints` و `PostgreSQL ENUM`) المثبتة في مرجع مصدر الحقيقة (`Database_Schema_Extraction.md` ووثائق المراحل العشر `SQLite_Phase_01` إلى `SQLite_Phase_10`).
>
> 1. **منع الافتراض:** لا يجوز إنشاء أي Enum بناءً على اسم العمود (`Column Name`) أو نوعه (`VARCHAR/TEXT`) أو التخمين البرمجي أو نماذج `Laravel/Flutter` إذا لم يوثق له قيد تحقق صريح في المرجع الرسمي. في حال غياب القيد الرسمي، يُصنف العمود تحت بند **`No Official Enum`**.
> 2. **تخزين SQLite:** تخزن جميع قيم Enums في قاعدة بيانات `SQLite ERP` كـ **`TEXT`** بالسلاسل النصية الدقيقة الموضحة في وثيقة المرجع.
> 3. **عدم الإنشاء البرمجي:** هذه الوثيقة تمثل مرجع التوثيق الهندسي فقط، ولا تتضمن أي أكواد برمجية لـ `Dart Enums` أو `Drift TypeConverters` أو `Migrations`.

---

## Part 1: Official Database Enumerations (`CHECK Constraints` & `PostgreSQL ENUMs`)

### 1. `AccountTypeStatus`
- **Source:** CHECK Constraint (`chk_accounts_status` / `Database_Schema_Extraction.md`)
- **Used By:** `account_types` (`status`)
- **Values:**
  1. `Active`
  2. `Suspended`
  3. `Closed`
- **Description:** Operational status of the general ledger account type.
- **SQLite Storage:** `TEXT`

---

### 2. `SystemSettingType`
- **Source:** CHECK Constraint (`chk_ss_type` / `Database_Schema_Extraction.md`)
- **Used By:** `system_settings` (`setting_type`)
- **Values:**
  1. `string`
  2. `integer`
  3. `boolean`
  4. `json`
- **Description:** Data type classification of the stored system setting value.
- **SQLite Storage:** `TEXT`

---

### 3. `PrintPaperSize`
- **Source:** CHECK Constraint (`chk_ps_paper_size` / `Database_Schema_Extraction.md`)
- **Used By:** `print_settings` (`paper_size`)
- **Values:**
  1. `A4`
  2. `A5`
  3. `Thermal80mm`
  4. `Thermal58mm`
- **Description:** Paper format specification for document layout printing.
- **SQLite Storage:** `TEXT`

---

### 4. `SequenceResetFrequency`
- **Source:** CHECK Constraint (`chk_seq_reset` / `Database_Schema_Extraction.md`)
- **Used By:** `sequences` (`reset_frequency`)
- **Values:**
  1. `Never`
  2. `Daily`
  3. `Monthly`
  4. `Yearly`
- **Description:** Interval cycle at which document sequence counters reset to zero or starting step.
- **SQLite Storage:** `TEXT`

---

### 5. `InventoryTransactionType`
- **Source:** CHECK Constraint (`chk_inv_tx_type` / `Database_Schema_Extraction.md`)
- **Used By:** `inventory_transactions` (`transaction_type`)
- **Values:**
  1. `Receipt`
  2. `Dispatch`
  3. `Adjustment In`
  4. `Adjustment Out`
  5. `Opening Balance`
- **Description:** Functional categorization of stock movement transaction.
- **SQLite Storage:** `TEXT`

---

### 6. `InventoryMovementDirection`
- **Source:** CHECK Constraint (`chk_inv_tx_movement` / `Database_Schema_Extraction.md`)
- **Used By:** `inventory_transactions` (`movement_direction`)
- **Values:**
  1. `IN`
  2. `OUT`
- **Description:** Physical direction of inventory flow into or out of the warehouse.
- **SQLite Storage:** `TEXT`

---

### 7. `InventoryTransactionStatus`
- **Source:** CHECK Constraint (`chk_inv_tx_status` / `Database_Schema_Extraction.md`)
- **Used By:** `inventory_transactions` (`status`)
- **Values:**
  1. `Draft`
  2. `Posted`
  3. `Reversed`
- **Description:** Workflow state of the inventory movement document.
- **SQLite Storage:** `TEXT`

---

### 8. `InventoryReferenceType`
- **Source:** CHECK Constraint (`chk_inv_tx_ref` / `Database_Schema_Extraction.md`)
- **Used By:** `inventory_transactions` (`reference_type`)
- **Values:**
  1. `SalesInvoice`
  2. `SalesReturn`
  3. `PurchaseInvoice`
  4. `PurchaseReturn`
  5. `Transfer`
  6. `Adjustment`
- **Description:** Polymorphic source document type triggering the inventory transaction (can be NULL if standalone).
- **SQLite Storage:** `TEXT`

---

### 9. `InventoryTransferStatus`
- **Source:** CHECK Constraint (`chk_inv_transfers_status` / `Database_Schema_Extraction.md`)
- **Used By:** `inventory_transfers` (`status`)
- **Values:**
  1. `Pending`
  2. `Completed`
  3. `Cancelled`
- **Description:** Execution state of stock transfer between two warehouses.
- **SQLite Storage:** `TEXT`

---

### 10. `TaxType`
- **Source:** CHECK Constraint (`chk_tax_type` / `Database_Schema_Extraction.md`)
- **Used By:** `taxes` (`tax_type`)
- **Values:**
  1. `Percentage`
  2. `Fixed`
- **Description:** Computation method applied for tax rate calculation.
- **SQLite Storage:** `TEXT`

---

### 11. `CustomerOpeningBalanceType`
- **Source:** CHECK Constraint (`chk_cust_bal_type` / `Database_Schema_Extraction.md`)
- **Used By:** `customers` (`opening_balance_type`)
- **Values:**
  1. `debit`
  2. `credit`
- **Description:** Balance side indicator for customer initial opening balance.
- **SQLite Storage:** `TEXT`

---

### 12. `SalesChannelType`
- **Source:** CHECK Constraint (`chk_chan_type` / `Database_Schema_Extraction.md`)
- **Used By:** `channels` (`channel_type`)
- **Values:**
  1. `POS`
  2. `Ecommerce`
  3. `B2B`
  4. `Marketplace`
  5. `Other`
- **Description:** Platform category classification of the sales channel.
- **SQLite Storage:** `TEXT`

---

### 13. `CartStatus`
- **Source:** CHECK Constraint (`chk_cart_status` / `Database_Schema_Extraction.md`)
- **Used By:** `carts` (`status`)
- **Values:**
  1. `Active`
  2. `Converted`
  3. `Abandoned`
- **Description:** Lifecycle state of customer or POS shopping cart.
- **SQLite Storage:** `TEXT`

---

### 14. `SalesInvoicePaymentStatus`
- **Source:** CHECK Constraint (`chk_si_payment` / `Database_Schema_Extraction.md`)
- **Used By:** `sales_invoices` (`payment_status`)
- **Values:**
  1. `Unpaid`
  2. `Partial`
  3. `Paid`
- **Description:** Settlement progress of the sales invoice against payments.
- **SQLite Storage:** `TEXT`

---

### 15. `SalesInvoiceStatus`
- **Source:** CHECK Constraint (`chk_si_status` / `Database_Schema_Extraction.md`)
- **Used By:** `sales_invoices` (`status`)
- **Values:**
  1. `Draft`
  2. `Posted`
  3. `Reversed`
- **Description:** Document workflow status of the sales invoice.
- **SQLite Storage:** `TEXT`

---

### 16. `CustomerReceivableStatus`
- **Source:** CHECK Constraint (`chk_cr_status` / `Database_Schema_Extraction.md`)
- **Used By:** `customer_receivables` (`status`)
- **Values:**
  1. `Unpaid`
  2. `Partial`
  3. `Paid`
- **Description:** Payment collection status of the accounts receivable sub-ledger record.
- **SQLite Storage:** `TEXT`

---

### 17. `ReceivableEntryType`
- **Source:** CHECK Constraint (`chk_re_type` / `Database_Schema_Extraction.md`)
- **Used By:** `receivable_entries` (`entry_type`)
- **Values:**
  1. `Payment`
  2. `Adjustment`
  3. `WriteOff`
- **Description:** Accounting classification of the receivable allocation entry.
- **SQLite Storage:** `TEXT`

---

### 18. `SupplierOpeningBalanceType`
- **Source:** CHECK Constraint (`chk_sup_bal_type` / `Database_Schema_Extraction.md`)
- **Used By:** `suppliers` (`opening_balance_type`)
- **Values:**
  1. `debit`
  2. `credit`
- **Description:** Balance side indicator for supplier initial opening balance.
- **SQLite Storage:** `TEXT`

---

### 19. `PurchaseInvoicePaymentStatus`
- **Source:** CHECK Constraint (`chk_pi_payment` / `Database_Schema_Extraction.md`)
- **Used By:** `purchase_invoices` (`payment_status`)
- **Values:**
  1. `Unpaid`
  2. `Partial`
  3. `Paid`
- **Description:** Settlement progress of the purchase invoice against payments.
- **SQLite Storage:** `TEXT`

---

### 20. `PurchaseInvoiceStatus`
- **Source:** CHECK Constraint (`chk_pi_status` / `Database_Schema_Extraction.md`)
- **Used By:** `purchase_invoices` (`status`)
- **Values:**
  1. `Draft`
  2. `Posted`
  3. `Reversed`
- **Description:** Document workflow status of the purchase invoice.
- **SQLite Storage:** `TEXT`

---

### 21. `SupplierPayableStatus`
- **Source:** CHECK Constraint (`chk_sp_status` / `Database_Schema_Extraction.md`)
- **Used By:** `supplier_payables` (`status`)
- **Values:**
  1. `Unpaid`
  2. `Partial`
  3. `Paid`
- **Description:** Payment disbursement status of the accounts payable sub-ledger record.
- **SQLite Storage:** `TEXT`

---

### 22. `PayableEntryType`
- **Source:** CHECK Constraint (`chk_pe_type` / `Database_Schema_Extraction.md`)
- **Used By:** `payable_entries` (`entry_type`)
- **Values:**
  1. `Payment`
  2. `Adjustment`
  3. `WriteOff`
- **Description:** Accounting classification of the payable allocation entry.
- **SQLite Storage:** `TEXT`

---

### 23. `FiscalYearStatus`
- **Source:** CHECK Constraint (`chk_fy_status` / `Database_Schema_Extraction.md`)
- **Used By:** `fiscal_years` (`status`)
- **Values:**
  1. `Open`
  2. `Closed`
- **Description:** Financial status of the fiscal year.
- **SQLite Storage:** `TEXT`

---

### 24. `FiscalPeriodStatus`
- **Source:** CHECK Constraint (`chk_fp_status` / `Database_Schema_Extraction.md`)
- **Used By:** `fiscal_periods` (`status`)
- **Values:**
  1. `Open`
  2. `Closed`
- **Description:** Financial status of the period within a fiscal year.
- **SQLite Storage:** `TEXT`

---

### 25. `AccountNormalBalance`
- **Source:** CHECK Constraint (`chk_coa_balance` / `Database_Schema_Extraction.md`)
- **Used By:** `chart_of_accounts` (`normal_balance`)
- **Values:**
  1. `Debit`
  2. `Credit`
- **Description:** Standard accounting balance direction of general ledger account.
- **SQLite Storage:** `TEXT`

---

### 26. `JournalEntryType`
- **Source:** CHECK Constraint (`chk_je_jnl_type`, `chk_je_doc_type` / `Database_Schema_Extraction.md`)
- **Used By:** `journal_entries` (`journal_type`, `document_type`)
- **Values:**
  1. `Manual`
  2. `SalesInvoice`
  3. `PurchaseInvoice`
  4. `Payment`
  5. `InventoryAdjustment`
  6. `Reverse`
- **Description:** Functional origin and document classification of general ledger journal entry.
- **SQLite Storage:** `TEXT`

---

### 27. `JournalEntryStatus`
- **Source:** CHECK Constraint (`chk_je_status` / `Database_Schema_Extraction.md`)
- **Used By:** `journal_entries` (`status`)
- **Values:**
  1. `Draft`
  2. `Posted`
  3. `Reversed`
- **Description:** Posting workflow state of the journal entry.
- **SQLite Storage:** `TEXT`

---

### 28. `JournalLineType`
- **Source:** CHECK Constraint (`chk_jel_type` / `Database_Schema_Extraction.md`)
- **Used By:** `journal_entry_lines` (`type`)
- **Values:**
  1. `Debit`
  2. `Credit`
- **Description:** Direction indicator of individual journal line transaction.
- **SQLite Storage:** `TEXT`

---

### 29. `AccountingPeriodStatus`
- **Source:** CHECK Constraint (`chk_ap_status` / `Database_Schema_Extraction.md`)
- **Used By:** `accounting_periods` (`status`)
- **Values:**
  1. `Open`
  2. `Closed`
  3. `Locked`
- **Description:** Financial closing and modification lock status of accounting period.
- **SQLite Storage:** `TEXT`

---

### 30. `PaymentMethodType`
- **Source:** CHECK Constraint (`chk_pm_type` / `Database_Schema_Extraction.md`)
- **Used By:** `payment_methods` (`payment_type`)
- **Values:**
  1. `Cash`
  2. `Bank`
  3. `Card`
  4. `DigitalWallet`
  5. `Other`
- **Description:** Instrument classification of payment method.
- **SQLite Storage:** `TEXT`

---

### 31. `CashRegisterStatus`
- **Source:** CHECK Constraint (`chk_cr_status` / `Database_Schema_Extraction.md`)
- **Used By:** `cash_registers` (`status`)
- **Values:**
  1. `Open`
  2. `Closed`
- **Description:** Operational shift session status of point-of-sale cash register.
- **SQLite Storage:** `TEXT`

---

### 32. `CashTransactionType`
- **Source:** CHECK Constraint (`chk_ct_type` / `Database_Schema_Extraction.md`)
- **Used By:** `cash_transactions` (`transaction_type`)
- **Values:**
  1. `Deposit`
  2. `Withdrawal`
  3. `Transfer In/Out`
  4. `Adjustment`
  5. `Payment`
  6. `Receipt`
- **Description:** Categorization of cash flow movements inside a cash register.
- **SQLite Storage:** `TEXT`

---

### 33. `BankAccountStatus`
- **Source:** CHECK Constraint (`chk_ba_status` / `Database_Schema_Extraction.md`)
- **Used By:** `bank_accounts` (`status`)
- **Values:**
  1. `Active`
  2. `Frozen`
  3. `Closed`
- **Description:** Operational availability status of treasury bank account.
- **SQLite Storage:** `TEXT`

---

### 34. `BankTransactionType`
- **Source:** CHECK Constraint (`chk_bt_type` / `Database_Schema_Extraction.md`)
- **Used By:** `bank_transactions` (`transaction_type`)
- **Values:**
  1. `Deposit`
  2. `Withdrawal`
  3. `Transfer In/Out`
  4. `Adjustment`
  5. `Bank Fee`
  6. `Interest`
  7. `Opening Balance`
- **Description:** Classification of bank statement or ledger movement.
- **SQLite Storage:** `TEXT`

---

### 35. `BankTransactionDirection`
- **Source:** CHECK Constraint (`chk_bt_direction` / `Database_Schema_Extraction.md`)
- **Used By:** `bank_transactions` (`direction`)
- **Values:**
  1. `Credit`
  2. `Debit`
- **Description:** Direction of flow affecting bank account balance.
- **SQLite Storage:** `TEXT`

---

### 36. `PaymentTransactionType`
- **Source:** CHECK Constraint (`chk_pay_type` / `Database_Schema_Extraction.md`)
- **Used By:** `payments` (`payment_type`)
- **Values:**
  1. `Receipt`
  2. `Payment`
  3. `Refund`
  4. `Adjustment`
  5. `Transfer`
- **Description:** Financial direction and functional classification of payment document.
- **SQLite Storage:** `TEXT`

---

### 37. `PaymentContactType`
- **Source:** CHECK Constraint (`chk_pay_contact_type` / `Database_Schema_Extraction.md`)
- **Used By:** `payments` (`contact_type`)
- **Values:**
  1. `Customer`
  2. `Supplier`
  3. `Employee`
  4. `Other`
- **Description:** Entity classification of the party receiving or issuing the payment voucher.
- **SQLite Storage:** `TEXT`

---

### 38. `PaymentStatus`
- **Source:** CHECK Constraint (`chk_pay_status` / `Database_Schema_Extraction.md`)
- **Used By:** `payments` (`status`)
- **Values:**
  1. `Draft`
  2. `Posted`
  3. `Reversed`
- **Description:** Workflow state of payment voucher document.
- **SQLite Storage:** `TEXT`

---

### 39. `BankReconciliationStatus`
- **Source:** CHECK Constraint (`chk_br_status` / `Database_Schema_Extraction.md`)
- **Used By:** `bank_reconciliations` (`status`)
- **Values:**
  1. `Draft`
  2. `Completed`
- **Description:** Workflow state of bank account reconciliation statement.
- **SQLite Storage:** `TEXT`

---

### 40. `EmployeeStatus`
- **Source:** CHECK Constraint (`chk_emp_status` / `Database_Schema_Extraction.md`)
- **Used By:** `employees` (`status`)
- **Values:**
  1. `Active`
  2. `Terminated`
  3. `OnLeave`
- **Description:** HR personnel employment status.
- **SQLite Storage:** `TEXT`

---

### 41. `FixedAssetStatus`
- **Source:** CHECK Constraint (`chk_fa_status` / `Database_Schema_Extraction.md`)
- **Used By:** `fixed_assets` (`status`)
- **Values:**
  1. `Draft`
  2. `Active`
  3. `Depreciating`
  4. `Fully Depreciated`
  5. `Disposed`
- **Description:** Lifecycle status of fixed asset from acquisition to disposal.
- **SQLite Storage:** `TEXT`

---

### 42. `DepreciationScheduleStatus`
- **Source:** CHECK Constraint (`chk_ds_status` / `Database_Schema_Extraction.md`)
- **Used By:** `depreciation_schedules` (`status`)
- **Values:**
  1. `Pending`
  2. `Ready`
  3. `Posted`
  4. `Cancelled`
- **Description:** Execution state of periodic depreciation schedule line.
- **SQLite Storage:** `TEXT`

---

### 43. `ExpenseStatus`
- **Source:** CHECK Constraint (`chk_exp_status` / `Database_Schema_Extraction.md`)
- **Used By:** `expenses` (`status`)
- **Values:**
  1. `Draft`
  2. `Posted`
  3. `Cancelled`
- **Description:** Workflow state of recorded expense voucher.
- **SQLite Storage:** `TEXT`

---

### 44. `StockAdjustmentType`
- **Source:** CHECK Constraint (`chk_sa_type` / `Database_Schema_Extraction.md`)
- **Used By:** `stock_adjustments` (`adjustment_type`)
- **Values:**
  1. `Increase`
  2. `Decrease`
  3. `Damage`
  4. `Loss`
- **Description:** Physical reason classification of inventory stock count adjustment.
- **SQLite Storage:** `TEXT`

---

### 45. `StockAdjustmentStatus`
- **Source:** CHECK Constraint (`chk_sa_status` / `Database_Schema_Extraction.md`)
- **Used By:** `stock_adjustments` (`status`)
- **Values:**
  1. `Draft`
  2. `Posted`
- **Description:** Workflow state of stock adjustment document.
- **SQLite Storage:** `TEXT`

---

## Part 2: Columns Without Official Enumerations (`No Official Enum`)

الأعمدة التالية تم فحصها في مرجع مصدر الحقيقة (`Database_Schema_Extraction.md`) وتبين أنها لا تمتلك قيد `CHECK Constraint` أو `PostgreSQL ENUM` صريح يُحدد قيمها بقائمة مغلقة، وبالتالي يمنع منسوب المعمارية إنشاء Enum لها دون نص صريح من المرجع:

| Table Name | Column Name | PostgreSQL Type | Status / Reason |
| :--- | :--- | :--- | :--- |
| `orders` | `payment_status` | `string(20)` | **No Official Enum** (No CHECK constraint exists in extraction) |
| `orders` | `status` | `string(30)` | **No Official Enum** (No CHECK constraint exists in extraction) |
| `sales_returns` | `status` | `string(20)` | **No Official Enum** (No CHECK constraint exists in extraction) |
| `purchase_returns` | `status` | `string(20)` | **No Official Enum** (No CHECK constraint exists in extraction) |
| `fixed_assets` | `depreciation_method` | `string(50)` | **No Official Enum** (Documented with free-text example `e.g. StraightLine`) |
| `activity_logs` | `action` | `string(100)` | **No Official Enum** (Documented with examples `e.g. create, update, post`) |
| `attachments` | `entity_type` | `string(50)` | **No Official Enum** (Polymorphic entity string) |
| `cash_transactions`| `document_type` | `string(100)` | **No Official Enum** (Polymorphic reference document string) |
| `system_settings` | `setting_key` | `string(100)` | **No Official Enum** (Free configuration keys) |
| `print_settings` | `document_type` | `string(50)` | **No Official Enum** (Documented with examples `e.g. SalesInvoice, Receipt`) |
| `sequences` | `document_type` | `string(50)` | **No Official Enum** (Documented with examples `e.g. SalesInvoice, PurchaseInvoice`) |
| `account_mappings` | `mapping_key` | `string(100)` | **No Official Enum** (Free mapping keys `e.g. default_sales_tax`) |

---

## Final Verification Report

- CHECK Constraints ........ PASS
- PostgreSQL ENUM .......... PASS
- Duplicate Enums .......... PASS
- Missing Enums ............ PASS
- SQLite Compatibility ..... PASS
- Architecture Compliance .. PASS

**SQLite Enum Specification Completed ✅**
