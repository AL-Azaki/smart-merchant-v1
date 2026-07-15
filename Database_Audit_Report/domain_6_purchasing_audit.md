# 🔍 Database Audit Report — Domain 6: PURCHASING

**Schema:** Smart Merchant ERP v2.1  
**Date:** 2026-07-11  
**Domain Scope:** Lines 980–1187

---

## 📋 Domain Overview

| # | Entity | Type | Lines | Description |
|---|--------|------|-------|-------------|
| 1 | `suppliers` | Master | 992–1020 | Supplier records per business |
| 2 | `purchase_invoices` | Transactional | 1027–1079 | Purchase invoice header |
| 3 | `purchase_invoice_items` | Detail | 1085–1113 | Invoice line items |
| 4 | `purchase_returns` | Transactional | 1120–1156 | Purchase return header |
| 5 | `purchase_return_items` | Detail | 1162–1187 | Return line items |

**Total Entities in Domain: 5**

---

## 🔬 Entity-by-Entity Audit

---

### 1. `suppliers` (Lines 992–1020)

#### Attributes Review

| Column | Type | Nullable | Verdict |
|--------|------|----------|---------|
| `id` | CHAR(36) | NOT NULL | ✅ |
| `business_id` | CHAR(36) | NOT NULL | ✅ |
| `supplier_name` | VARCHAR(255) | NOT NULL | ✅ |
| `contact_person` | VARCHAR(255) | NULL | ✅ |
| `phone` | VARCHAR(30) | NULL | ✅ |
| `supplier_address` | VARCHAR(255) | NULL | ✅ |
| `default_currency_id` | CHAR(36) | NULL | ✅ FK مؤجل |
| `payment_term_id` | CHAR(36) | NULL | ✅ FK مؤجل |
| `payable_account_id` | CHAR(36) | NULL | ✅ FK مؤجل — ربط بحساب دائنين |
| `credit_limit` | DECIMAL(18,2) | **NULL** DEFAULT 0.00 | ⚠️ |
| `opening_balance` | DECIMAL(18,2) | NOT NULL DEFAULT 0.00 | ✅ |
| `opening_balance_type` | ENUM('debit','credit') | NULL | ✅ |
| `opening_balance_date` | DATE | NULL | ✅ |
| `is_active` / `deleted_at` | — | — | ✅ |

#### Post-Creation FKs (Lines 2155–2161)

| FK | Target | Verdict |
|----|--------|---------|
| `fk_suppliers_currency` | → currencies(id) SET NULL | ✅ |
| `fk_suppliers_term` | → payment_terms(business_id, id) | ✅ Composite |
| `fk_suppliers_payable_account` | → chart_of_accounts(business_id, id) | ✅ Composite |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | `credit_limit` هو **NULL** بينما في `customers` هو **NOT NULL** — عدم تناسق. **اقتراح**: توحيد إلى NOT NULL DEFAULT 0.00 كما في customers. |
| 2 | ⚠️ Minor | نفس ملاحظة `customers` — لا يوجد CHECK يفرض أن `opening_balance_type IS NOT NULL` عندما `opening_balance > 0`. |
| 3 | ✅ Pass | `payable_account_id` — ربط بحساب دائنين في شجرة الحسابات. ممتاز. |
| 4 | ✅ Pass | التصميم متماثل مع `customers` — اتساق جيد. |

#### Verdict: ✅ APPROVED — مع توحيد credit_limit nullability.

---

### 2. `purchase_invoices` (Lines 1027–1079)

#### Attributes Review

**مقارنة مع sales_invoices:**

| Feature | sales_invoices | purchase_invoices | Verdict |
|---------|---------------|-------------------|---------|
| Multi-currency amounts | ✅ | ✅ | ✅ متطابق |
| Status workflow | Draft→Posted→Cancelled | نفسه | ✅ |
| exchange_rate validation | ✅ | ✅ | ✅ |
| Totals validation | ✅ | ✅ | ✅ |
| warehouse_id | ❌ (في البنود) | ✅ (header + بنود) | ✅ مختلف — مبرر |
| payment_status | ✅ Unpaid/Partial/Paid | ❌ لا يوجد | 🔴 **مفقود** |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `uq_purchase_invoices_number` | UNIQUE (business_id, invoice_number) | ✅ |
| `fk_pur_inv_branch` | Composite FK | ✅ |
| `fk_pur_inv_supplier` | Composite FK | ✅ |
| `fk_pur_inv_warehouse` | Composite FK | ✅ Default warehouse |
| `fk_pur_inv_created_by` | FK → users(id) | ✅ |
| All checks | ✅ | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | 🔴 **Issue** | **لا يوجد `payment_status`** في `purchase_invoices` — بينما موجود في `sales_invoices`. هذا يعني لا يمكن تتبع حالة الدفع للمشتريات على مستوى DB. **اقتراح: إضافة `payment_status ENUM('Unpaid','Partial','Paid') NOT NULL DEFAULT 'Unpaid'`**. |
| 2 | ⚠️ Minor | `warehouse_id` في Header — هذا المخزن الافتراضي للاستلام. جيد لكن البنود لديها `warehouse_id` خاص بها أيضاً — تصميم مرن. |
| 3 | ✅ Pass | لا يوجد trigger لحد ائتمان المورد — مقبول لأن المورد هو الذي يمنح الائتمان وليس العكس. |

#### Verdict: ⚠️ APPROVED WITH NOTE — يجب إضافة `payment_status`.

---

### 3. `purchase_invoice_items` (Lines 1085–1113)

#### Review

| Aspect | Verdict |
|--------|---------|
| FK Composite → purchase_invoices, product_units, warehouses | ✅ |
| All price/qty checks | ✅ |
| base_line_total for multi-currency | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | لا يوجد `cost_price` / `cost_total` مثل `sales_invoice_items` — لكن في المشتريات `unit_price` هو نفسه cost. **مقبول**. |

#### Verdict: ✅ APPROVED

---

### 4. `purchase_returns` (Lines 1120–1156)

#### Review

تصميم متماثل مع `sales_returns`. جميع الحقول والعلاقات صحيحة.

| Feature | Verdict |
|---------|---------|
| FK → purchase_invoices (Composite) | ✅ |
| Multi-currency | ✅ |
| Status workflow | ✅ |

#### Verdict: ✅ APPROVED

---

### 5. `purchase_return_items` (Lines 1162–1187)

#### Review

| Feature | Verdict |
|---------|---------|
| FK → purchase_invoice_items(id) | ✅ مربوط ببند فاتورة |
| FK → warehouses (Composite) | ✅ |
| Quantity/price checks | ✅ |

#### Triggers

| Trigger | Purpose | Verdict |
|---------|---------|---------|
| `trg_purchase_return_qty_bi` | يمنع إرجاع كمية أكبر من المشتراة | ✅ |
| `trg_purchase_return_qty_bu` | نفس التحقق عند UPDATE | ✅ |

#### Verdict: ✅ APPROVED

---

## 🏗️ Normalization Check

| NF | Status |
|----|--------|
| 1NF–BCNF | ✅ Pass — نفس ملاحظات domain 5 حول base_* amounts (denormalization مقصود) |

---

## 📝 Consolidated Findings

| # | Table | Severity | Issue | Recommendation |
|---|-------|----------|-------|----------------|
| 1 | `purchase_invoices` | 🔴 Medium-High | لا يوجد `payment_status` | **إضافة عمود payment_status** |
| 2 | `suppliers` | ⚠️ Minor | `credit_limit` NULL vs NOT NULL (عدم تناسق مع customers) | توحيد |
| 3 | `suppliers` | ⚠️ Minor | لا يوجد CHECK على opening_balance_type | إضافة CHECK |

---

## ✅ Domain 6 Final Verdict

> ### 🟡 APPROVED WITH REQUIRED FIX
> 
> Domain 6 (PURCHASING) **شبه جاهز**. التصميم متسق مع domain المبيعات، لكن:
> 
> **مطلوب قبل الاعتماد النهائي:**
> - 🔴 إضافة `payment_status` إلى `purchase_invoices`
>
> **تحسينات اختيارية:**
> - توحيد `credit_limit` nullability
> - إضافة CHECK على opening_balance_type

---

*يُتابع: Domain 7 — FINANCE*
