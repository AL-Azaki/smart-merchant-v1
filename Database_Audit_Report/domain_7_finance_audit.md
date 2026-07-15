# 🔍 Database Audit — Domain 7: FINANCE

**Lines:** 1189–1594 | **Entities:** 11

---

## 📋 Entities

| # | Entity | Lines | Description |
|---|--------|-------|-------------|
| 1 | `currencies` | 1202–1222 | Global currencies |
| 2 | `fiscal_years` | 1228–1245 | Fiscal years per business |
| 3 | `fiscal_periods` | 1251–1270 | Monthly periods within fiscal year |
| 4 | `chart_of_accounts` | 1278–1311 | COA tree per business |
| 5 | `payment_methods` | 1317–1335 | Payment methods per business |
| 6 | `journal_entries` | 1342–1392 | Journal entry header |
| 7 | `journal_entry_lines` | 1398–1430 | Debit/Credit lines |
| 8 | `payments` | 1436–1485 | All financial receipts/disbursements |
| 9 | `expense_categories` | 1491–1507 | Expense classification |
| 10 | `expenses` | 1513–1553 | Operational expenses |
| 11 | `opening_balances` | 1559–1594 | Opening balances per account per FY |

---

## 🔬 Audit Results

### 1. `currencies` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| Global (system-level, not per-business) | ✅ Correct design |
| `base_currency_single` GENERATED ALWAYS AS (CASE WHEN is_base_currency THEN 1 ELSE NULL) | ✅ Sentinel — one base currency |
| `uq_currencies_single_base` UNIQUE | ✅ Enforces single base |
| `uq_currencies_code` UNIQUE | ✅ |
| CHECK exchange_rate > 0, decimals 0–6 | ✅ |
| Bilingual names (ar + en) | ✅ |

**No issues found.**

---

### 2. `fiscal_years` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| UNIQUE (business_id, fiscal_year_code) | ✅ |
| Composite ref key (business_id, id) | ✅ |
| CHECK end_date >= start_date | ✅ |
| Status ENUM Open/Closed | ✅ |

**No issues found.**

---

### 3. `fiscal_periods` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| UNIQUE (fiscal_year_id, period_number) | ✅ |
| Composite FK → fiscal_years(business_id, id) | ✅ |
| CHECK period_number 1–12, dates valid | ✅ |
| Overlap prevention triggers (bi/bu) | ✅ **ممتاز** |

**No issues found.**

---

### 4. `chart_of_accounts` — 🔎 DEEP REVIEW

هذا هو الجدول الأهم في النظام المالي. مراجعة شاملة:

#### Attributes Review

| Column | Type | Verdict |
|--------|------|---------|
| `id` | CHAR(36) | ✅ |
| `business_id` | CHAR(36) NOT NULL | ✅ Multi-tenant |
| `parent_account_id` | CHAR(36) NULL | ✅ Tree hierarchy |
| `currency_id` | CHAR(36) NULL | ✅ Optional — for foreign currency accounts |
| `account_code` | VARCHAR(50) NOT NULL | ✅ |
| `account_name` | VARCHAR(255) NOT NULL | ✅ |
| `account_type` | ENUM('Asset','Liability','Equity','Revenue','Expense') | ✅ **5 أنواع رئيسية صحيحة** |
| `account_category` | VARCHAR(100) NULL | ✅ Sub-classification |
| `normal_balance` | ENUM('Debit','Credit') NOT NULL | ✅ |
| `account_level` | INT DEFAULT 1 | ✅ |
| `allow_posting` | BOOLEAN DEFAULT FALSE | ✅ Leaf vs Group |
| `is_system` | BOOLEAN DEFAULT FALSE | ✅ Protects system accounts |
| `is_active` | BOOLEAN DEFAULT TRUE | ✅ |

#### Constraints Review

| Constraint | Verdict |
|-----------|---------|
| `uq_chart_of_accounts_code` UNIQUE (business_id, account_code) | ✅ |
| `uq_chart_of_accounts_business_id_id` composite ref | ✅ |
| `fk_coa_business` → businesses | ✅ |
| `fk_coa_parent` → chart_of_accounts(id) | ⚠️ Should be composite |
| `fk_coa_currency` → currencies(id) | ✅ |
| CHECK account_level > 0 | ✅ |
| Indexes: business_id, parent_id, account_type | ✅ |

#### شجرة الحسابات — Chart of Accounts Completeness Check

**الأنواع الخمسة المطلوبة:**

| Type | Code Convention | normal_balance | Status |
|------|----------------|----------------|--------|
| Asset (أصول) | 1xxx | Debit | ✅ Supported |
| Liability (خصوم) | 2xxx | Credit | ✅ Supported |
| Equity (حقوق ملكية) | 3xxx | Credit | ✅ Supported |
| Revenue (إيرادات) | 4xxx | Credit | ✅ Supported |
| Expense (مصروفات) | 5xxx | Debit | ✅ Supported |

**الحسابات المطلوبة لعمليات النظام:**

| Account Purpose | Required For | Supported? |
|----------------|-------------|------------|
| Cash/Bank accounts | Payments, Receipts | ✅ via payment_methods.chart_of_account_id |
| Accounts Receivable (مدينون) | Sales invoices | ✅ via customers.receivable_account_id |
| Accounts Payable (دائنون) | Purchase invoices | ✅ via suppliers.payable_account_id |
| Revenue accounts | Sales posting | ✅ via journal_entry_lines |
| COGS (تكلفة المبيعات) | Inventory costing | ✅ via journal_entry_lines |
| Inventory account | Stock valuation | ✅ via journal_entry_lines |
| Expense accounts | Expenses | ✅ via expense_categories.chart_of_account_id |
| Fixed Assets | Asset registry | ✅ via fixed_assets → journal entries |
| Tax accounts (ضرائب) | Tax posting | ✅ via journal_entry_lines |
| Retained Earnings | Year-end closing | ✅ via ClosingEntry reference_type |
| Discount accounts | Sales/Purchase discounts | ✅ via journal_entry_lines |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Medium | `fk_coa_parent` يشير إلى `chart_of_accounts(id)` فقط — يجب أن يكون composite `(business_id, parent_account_id)` لمنع cross-business parents. **نفس مشكلة categories.** |
| 2 | ⚠️ Minor | لا يوجد CHECK يفرض توافق `normal_balance` مع `account_type` (مثلاً: Asset يجب أن يكون Debit). **اقتراح**: إضافة CHECK constraint. |
| 3 | ✅ Pass | `allow_posting` يفصل بين حسابات التجميع وحسابات الترحيل — ممتاز. |
| 4 | ✅ Pass | `is_system` يحمي الحسابات الأساسية من الحذف. |
| 5 | ✅ Pass | شجرة الحسابات **مكتملة** — تدعم جميع العمليات المحاسبية المطلوبة. |

#### Verdict: ⚠️ APPROVED WITH NOTE — FK parent يجب أن يكون composite.

---

### 5. `payment_methods` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| FK Composite → chart_of_accounts(business_id, id) | ✅ ربط بحساب نقدي/بنكي |
| UNIQUE (business_id, method_code) | ✅ |
| payment_type ENUM (Cash/Bank/Card/DigitalWallet/Other) | ✅ شامل |

**No issues found.**

---

### 6. `journal_entries` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| FK Composite → fiscal_years, fiscal_periods | ✅ |
| FK → currencies, users | ✅ |
| reference_type covers all operations | ✅ |
| Status: Draft→Posted→Reversed | ✅ |
| UNIQUE (business_id, journal_number) | ✅ |
| Balance validation trigger (`trg_journal_balance_before_post_bu`) | ✅ **ممتاز** — يمنع ترحيل قيد غير متوازن |

**reference_type values:**
```
SalesInvoice, SalesReturn, PurchaseInvoice, PurchaseReturn,
Payment, Expense, Manual, StockAdjustment, ClosingEntry
```
✅ **يغطي جميع العمليات المحاسبية**.

---

### 7. `journal_entry_lines` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| FK → journal_entries(id) CASCADE | ✅ |
| FK → chart_of_accounts(id) | ✅ |
| FK → currencies (line_currency_id) | ✅ Multi-currency per line |
| UNIQUE (journal_entry_id, line_number) | ✅ |
| `chk_jel_one_side` — debit XOR credit | ✅ **ممتاز** |
| `chk_jel_base_one_side` — same for base | ✅ |
| line_exchange_rate CHECK > 0 | ✅ |

**Key finding:** ✅ القيد `chk_jel_one_side` يضمن أن كل سطر إما مدين أو دائن (وليس كلاهما). هذا constraint محاسبي أساسي.

---

### 8. `payments` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| FK Composite → branches, payment_methods, chart_of_accounts | ✅ |
| FK → currencies | ✅ |
| payment_type ENUM شامل (Receipt/Payment/Refund/Adjustment/Transfer) | ✅ |
| reference_type polymorphic | ✅ |
| CHECK amount > 0 AND base_amount > 0 | ✅ |
| Comprehensive indexes (9 indexes) | ✅ |

**No issues found.**

---

### 9. `expense_categories` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| FK Composite → chart_of_accounts(business_id, id) | ✅ ربط بحساب مصروفات |
| UNIQUE (business_id, category_name) | ✅ |

---

### 10. `expenses` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| FK Composite → branches, expense_categories, payment_methods | ✅ |
| FK → currencies | ✅ |
| Multi-currency (amount + base_amount) | ✅ |
| CHECK amount > 0, base_amount > 0, exchange_rate > 0 | ✅ |
| Status Draft→Posted→Cancelled | ✅ |
| 8 indexes | ✅ |

---

### 11. `opening_balances` ✅ APPROVED

| Aspect | Verdict |
|--------|---------|
| UNIQUE (fiscal_year_id, chart_of_account_id) | ✅ One per account per FY |
| FK → fiscal_years, chart_of_accounts, currencies, users | ✅ |
| `chk_ob_one_side` — debit XOR credit | ✅ |
| `chk_ob_base_one_side` | ✅ |
| Business-match trigger (bi/bu) | ✅ **ممتاز** — يضمن تطابق FY و COA business |

---

## 📝 Consolidated Findings

| # | Table | Severity | Issue |
|---|-------|----------|-------|
| 1 | `chart_of_accounts` | ⚠️ Medium | FK parent should be composite (business_id, parent_account_id) |
| 2 | `chart_of_accounts` | ⚠️ Minor | No CHECK for normal_balance ↔ account_type consistency |

---

## ✅ Domain 7 Final Verdict

> ### 🟢 APPROVED
> 
> Domain 7 (FINANCE) **جاهز للاعتماد**. هذا أقوى domain في النظام:
> - ✅ شجرة الحسابات مكتملة وتدعم جميع العمليات
> - ✅ Journal balance enforcement via trigger
> - ✅ One-side debit/credit constraint
> - ✅ Multi-currency support at all levels
> - ✅ Fiscal year/period management with overlap prevention
> - ✅ Opening balances with business-match validation
> 
> **المشكلة الوحيدة**: FK parent في COA يجب أن يكون composite.
