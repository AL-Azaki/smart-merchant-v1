# 🔍 Database Audit Report — Domain 5: SALES

**Schema:** Smart Merchant ERP v2.1  
**Date:** 2026-07-11  
**Domain Scope:** Lines 655–978

---

## 📋 Domain Overview

| # | Entity | Type | Lines | Description |
|---|--------|------|-------|-------------|
| 1 | `customers` | Master | 667–695 | Customer records per business |
| 2 | `channels` | Master | 701–715 | Sales channels (POS, Ecommerce, etc.) |
| 3 | `orders` | Transactional | 779–831 | Sales orders (pre-invoice) |
| 4 | `order_items` | Detail | 837–861 | Order line items |
| 5 | `sales_invoices` | Transactional | 722–772 | Sales invoice header |
| 6 | `sales_invoice_items` | Detail | 867–901 | Invoice line items |
| 7 | `sales_returns` | Transactional | 908–944 | Sales return (credit note) header |
| 8 | `sales_return_items` | Detail | 950–978 | Return line items |

**Total Entities in Domain: 8**

---

## 🔬 Entity-by-Entity Audit

---

### 1. `customers` (Lines 667–695)

#### Attributes Review

| Column | Type | Nullable | Verdict |
|--------|------|----------|---------|
| `id` | CHAR(36) | NOT NULL | ✅ |
| `business_id` | CHAR(36) | NOT NULL | ✅ |
| `customer_name` | VARCHAR(255) | NOT NULL | ✅ |
| `phone` | VARCHAR(30) | NULL | ✅ |
| `email` | VARCHAR(255) | NULL | ✅ |
| `address` | TEXT | NULL | ✅ |
| `credit_limit` | DECIMAL(18,2) DEFAULT 0.00 | ✅ |
| `default_currency_id` | CHAR(36) | NULL | ✅ FK مؤجل |
| `payment_term_id` | CHAR(36) | NULL | ✅ FK مؤجل |
| `receivable_account_id` | CHAR(36) | NULL | ✅ FK مؤجل — **ممتاز**: ربط العميل بحساب مدينين |
| `opening_balance` | DECIMAL(18,2) DEFAULT 0.00 | ✅ |
| `opening_balance_type` | ENUM('debit','credit') | NULL | ✅ |
| `opening_balance_date` | DATE | NULL | ✅ |
| `is_active` / `deleted_at` | — | — | ✅ |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `uq_customers_business_id_id` | UNIQUE (business_id, id) | ✅ |
| `fk_customers_business` | FK → businesses(id) | ✅ |
| `chk_customers_credit_limit` | CHECK (credit_limit >= 0) | ✅ |
| `chk_customers_opening_balance` | CHECK (opening_balance >= 0) | ✅ |

#### Post-Creation FKs (Lines 2135–2141)

| FK | Target | Verdict |
|----|--------|---------|
| `fk_customers_currency` | → currencies(id) SET NULL | ✅ |
| `fk_customers_term` | → payment_terms(business_id, id) RESTRICT | ✅ Composite |
| `fk_customers_receivable_account` | → chart_of_accounts(business_id, id) RESTRICT | ✅ Composite |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | ربط العميل بحساب مدينين (`receivable_account_id`) — ممتاز للمحاسبة. |
| 2 | ✅ Pass | Opening balance + type + date — يدعم أرصدة افتتاحية. |
| 3 | ⚠️ Minor | لا يوجد UNIQUE على `(business_id, phone)` — يمكن أن يكون هناك عميلان بنفس رقم الهاتف. **قد يكون مقصوداً** (عميل شخص وعميل شركة بنفس الرقم). |
| 4 | ⚠️ Minor | `opening_balance_type` يجب أن يكون NOT NULL عندما `opening_balance > 0`. **اقتراح**: إضافة CHECK constraint: `CHECK (opening_balance = 0 OR opening_balance_type IS NOT NULL)`. |

#### Verdict: ✅ APPROVED — مع اقتراح CHECK للـ opening_balance.

---

### 2. `channels` (Lines 701–715)

#### Review

| Aspect | Verdict |
|--------|---------|
| PK, Attributes | ✅ |
| UNIQUE (business_id, channel_code) | ✅ |
| Composite ref key | ✅ |
| FK → businesses ON DELETE CASCADE | ✅ |
| channel_type ENUM | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | تصميم بسيط ونظيف. |
| 2 | ℹ️ Info | لا يوجد timestamps — مقبول لجدول إعداد. |

#### Verdict: ✅ APPROVED

---

### 3. `sales_invoices` (Lines 722–772)

#### Attributes Review — Multi-Currency Support

| Amount Fields | Transaction Currency | Base Currency | Verdict |
|---------------|---------------------|---------------|---------|
| sub_total | ✅ | base_sub_total ✅ | ✅ |
| discount_total | ✅ | base_discount_total ✅ | ✅ |
| tax_total | ✅ | base_tax_total ✅ | ✅ |
| grand_total | ✅ | base_grand_total ✅ | ✅ |

✅ **دعم كامل للعملات المتعددة** — كل مبلغ له نسخة في عملة المعاملة + عملة الأساس.

#### Other Attributes

| Column | Verdict |
|--------|---------|
| `exchange_rate` DECIMAL(18,8) DEFAULT 1 | ✅ |
| `payment_status` ENUM('Unpaid','Partial','Paid') | ✅ |
| `status` ENUM('Draft','Posted','Cancelled') | ✅ |
| `created_by` FK → users(id) | ✅ |
| `deleted_at` | ✅ Soft delete |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `uq_sales_invoice_number` | UNIQUE (business_id, invoice_number) | ✅ |
| `fk_sales_inv_branch` | FK Composite (business_id, branch_id) | ✅ |
| `fk_sales_inv_customer` | FK Composite (business_id, customer_id) | ✅ |
| `chk_sales_invoice_dates` | CHECK (due_date IS NULL OR due_date >= invoice_date) | ✅ |
| `chk_sales_invoice_exchange_rate` | CHECK (exchange_rate > 0) | ✅ |
| `chk_sales_invoice_totals` | CHECK all totals >= 0 | ✅ |

#### Indexes

```
business_id, branch_id, customer_id, status, payment_status, invoice_date, deleted_at
```
✅ **7 indexes** — تغطية شاملة لجميع أنماط الاستعلام.

#### Triggers

- `trg_credit_limit_sales_invoice_bi` — يتحقق من حد الائتمان عند insert ✅

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | تصميم متكامل للفوترة مع دعم كامل للعملات. |
| 2 | ⚠️ Minor | `customer_id` هو NULL — يعني يمكن إنشاء فاتورة بدون عميل (Walk-in customer). هذا مقبول لنظام POS. |
| 3 | ⚠️ Minor | Trigger حد الائتمان يتحقق فقط عند INSERT — لا يتحقق عند UPDATE (تغيير المبلغ). **اقتراح**: إضافة trigger للـ UPDATE أيضاً. |
| 4 | ⚠️ Minor | لا يوجد `payment_term_id` في الفاتورة — الأفضل وجوده لحساب `due_date` تلقائياً. لكن `due_date` موجود مباشرة وهذا مقبول. |

#### Verdict: ✅ APPROVED

---

### 4. `orders` (Lines 779–831)

#### Review

تصميم مطابق لـ `sales_invoices` مع إضافة `channel_id`. جميع الحقول والعلاقات صحيحة.

| Additional Feature | Verdict |
|-------------------|---------|
| `channel_id` FK Composite | ✅ ربط بقناة البيع |
| `status` ENUM شامل (7 values) | ✅ يدعم workflow كامل |
| `payment_status` ENUM | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | لا يوجد FK يربط `orders` بـ `sales_invoices` — التحويل من أمر إلى فاتورة يتم عبر Application. **مقبول** لأن الربط يتم عبر `order_item_id` في `sales_invoice_items`. |
| 2 | ✅ Pass | نفس نمط multi-currency. |

#### Verdict: ✅ APPROVED

---

### 5. `order_items` (Lines 837–861)

#### Review

| Aspect | Verdict |
|--------|---------|
| FK Composite → orders, product_units | ✅ |
| All price/qty checks | ✅ |
| `base_line_total` | ✅ |

#### Verdict: ✅ APPROVED

---

### 6. `sales_invoice_items` (Lines 867–901)

#### Attributes Review

| Column | Type | Verdict |
|--------|------|---------|
| All standard item fields | — | ✅ |
| `order_item_id` | CHAR(36) NULL | ✅ Optional link to original order |
| `warehouse_id` | CHAR(36) NOT NULL | ✅ **ممتاز** — يحدد من أي مخزن يتم البيع |
| `cost_price` | DECIMAL(18,2) | ✅ لحساب الربح |
| `cost_total` | DECIMAL(18,2) | ✅ total cost for margin analysis |

#### Constraints Review

| Constraint | Verdict |
|-----------|---------|
| FK Composite → sales_invoices, product_units, warehouses | ✅ |
| FK → order_items(id) ON DELETE SET NULL | ✅ |
| CHECK all values >= 0 | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | `warehouse_id` في بنود الفاتورة — ممتاز لدعم البيع من مخازن مختلفة. |
| 2 | ✅ Pass | `cost_price` / `cost_total` — يدعم تحليل الربحية. |
| 3 | ✅ Pass | `order_item_id` اختياري مع SET NULL — يسمح بالفوترة المباشرة بدون طلب. |

#### Verdict: ✅ APPROVED — تصميم ممتاز.

---

### 7. `sales_returns` (Lines 908–944)

#### Review

| Aspect | Verdict |
|--------|---------|
| FK → sales_invoices (Composite) | ✅ كل مرتجع مربوط بفاتورة |
| Multi-currency (total + base_total) | ✅ |
| Status workflow (Draft→Posted→Cancelled) | ✅ |
| created_by FK | ✅ |

#### Verdict: ✅ APPROVED

---

### 8. `sales_return_items` (Lines 950–978)

#### Attributes Review

| Column | Type | Verdict |
|--------|------|---------|
| `sales_invoice_item_id` | CHAR(36) NOT NULL | ✅ **ممتاز** — مربوط ببند فاتورة محدد |
| `warehouse_id` | CHAR(36) NOT NULL | ✅ المخزن الذي يعود إليه المرتجع |
| `cost_price` / `cost_total` | DECIMAL | ✅ |
| `total_price` / `base_total_price` | DECIMAL | ✅ Multi-currency |

#### Triggers

| Trigger | Purpose | Verdict |
|---------|---------|---------|
| `trg_sales_return_qty_bi` | يمنع إرجاع كمية أكبر من المباعة | ✅ **ممتاز** |
| `trg_sales_return_qty_bu` | نفس التحقق عند UPDATE | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | الربط ببند فاتورة محدد (`sales_invoice_item_id` NOT NULL) — يمنع المرتجعات بدون مرجع. |
| 2 | ✅ Pass | التحقق من الكميات المرتجعة عبر Trigger — حماية على مستوى DB. |

#### Verdict: ✅ APPROVED

---

## 🏗️ Normalization Check

| NF | Status | Notes |
|----|--------|-------|
| 1NF | ✅ Pass | ✅ |
| 2NF | ✅ Pass | ✅ |
| 3NF | ⚠️ Note | `base_*` amounts هي calculated fields (amount × exchange_rate) — **هذا denormalization مقصود ومقبول** لأداء التقارير وسلامة البيانات عند تغير أسعار الصرف. |
| BCNF | ✅ Pass | ✅ |

---

## 📝 Consolidated Findings

| # | Table | Severity | Issue | Recommendation |
|---|-------|----------|-------|----------------|
| 1 | `customers` | ⚠️ Minor | لا يوجد CHECK على opening_balance_type عندما opening_balance > 0 | إضافة CHECK |
| 2 | `sales_invoices` | ⚠️ Minor | Trigger حد الائتمان لا يتحقق عند UPDATE | إضافة trigger للـ UPDATE |
| 3 | `sales_invoices` | ℹ️ Info | لا يوجد payment_term_id | مقبول — due_date موجود مباشرة |

---

## ✅ Domain 5 Final Verdict

> ### 🟢 APPROVED
> 
> Domain 5 (SALES) **جاهز للاعتماد**. هذا أحد أقوى الـ Domains في النظام:
> - ✅ Multi-currency support كامل
> - ✅ Order → Invoice → Return workflow
> - ✅ Credit limit enforcement via triggers
> - ✅ Return quantity validation
> - ✅ Per-item warehouse tracking
> - ✅ Cost tracking for profitability analysis
> - ✅ Comprehensive indexing
> 
> **لا توجد مشاكل حرجة.**

---

*يُتابع في التقرير التالي: Domain 6 — PURCHASING*
