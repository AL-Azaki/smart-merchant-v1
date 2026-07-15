# 🔍 Database Audit Report — Domain 4: INVENTORY

**Schema:** Smart Merchant ERP v2.1  
**Date:** 2026-07-11  
**Domain Scope:** Lines 504–653

---

## 📋 Domain Overview

| # | Entity | Type | Lines | Description |
|---|--------|------|-------|-------------|
| 1 | `warehouses` | Master | 514–537 | Stock warehouses per branch |
| 2 | `inventories` | State | 543–564 | Current stock level per product_unit per warehouse |
| 3 | `inventory_transactions` | Ledger | 570–597 | Immutable ledger of stock movements |
| 4 | `inventory_transfers` | Transactional | 603–631 | Stock transfer header between warehouses |
| 5 | `inventory_transfer_items` | Detail | 637–653 | Line items of a stock transfer |

**Total Entities in Domain: 5**

---

## 🔬 Entity-by-Entity Audit

---

### 1. `warehouses` (Lines 514–537)

#### Attributes Review

| Column | Type | Nullable | Default | Verdict |
|--------|------|----------|---------|---------|
| `id` | CHAR(36) | NOT NULL | UUID() | ✅ |
| `business_id` | CHAR(36) | NOT NULL | — | ✅ |
| `branch_id` | CHAR(36) | NOT NULL | — | ✅ |
| `warehouse_name` | VARCHAR(255) | NOT NULL | — | ✅ |
| `warehouse_code` | VARCHAR(100) | NOT NULL | — | ✅ |
| `address` | VARCHAR(255) | NULL | — | ✅ |
| `is_default` | BOOLEAN | NOT NULL | FALSE | ✅ |
| `default_branch_id` | CHAR(36) | NULL | NULL | ✅ Sentinel column |
| `is_active` | BOOLEAN | NOT NULL | TRUE | ✅ |
| `created_at` / `updated_at` | TIMESTAMP | NOT NULL | — | ✅ |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_warehouses` | PK (id) | ✅ |
| `uq_warehouses_code` | UNIQUE (business_id, warehouse_code) | ✅ |
| `uq_warehouses_business_id_id` | UNIQUE (business_id, id) | ✅ Composite ref |
| `uq_warehouses_default_branch` | UNIQUE (default_branch_id) | ✅ One default per branch |
| `fk_warehouses_business` | FK → businesses(id) | ✅ |
| `fk_warehouses_branch` | FK (business_id, branch_id) → branches(business_id, id) | ✅ Composite |

#### Triggers

- `trg_warehouses_default_branch_bi/bu` — Manages `default_branch_id` sentinel ✅

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | نمط الـ default warehouse per branch مُحكم عبر sentinel pattern. |
| 2 | ✅ Pass | Composite FK يضمن أن الفرع ينتمي لنفس الأعمال. |
| 3 | ⚠️ Minor | لا يوجد `deleted_at` — لا يمكن حذف مخزن soft delete. **مقبول** لأن حذف مخزن له مخزون يجب أن يمنع. |

#### Verdict: ✅ APPROVED

---

### 2. `inventories` (Lines 543–564)

#### Attributes Review

| Column | Type | Verdict |
|--------|------|---------|
| `id` | CHAR(36) | ✅ |
| `warehouse_id` | CHAR(36) NOT NULL | ✅ |
| `product_unit_id` | CHAR(36) NOT NULL | ✅ |
| `quantity` | DECIMAL(18,3) DEFAULT 0.000 | ✅ Supports fractional |
| `average_cost` | DECIMAL(18,2) DEFAULT 0.00 | ✅ AVCO method |
| `alert_quantity` | DECIMAL(18,3) DEFAULT 0.000 | ✅ Reorder point |
| `updated_at` | TIMESTAMP | ✅ |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `uq_inventories_warehouse_unit` | UNIQUE (warehouse_id, product_unit_id) | ✅ One record per pair |
| `fk_inventories_warehouse` | FK → warehouses(id) RESTRICT | ✅ |
| `fk_inventories_product_unit` | FK → product_units(id) RESTRICT | ✅ |
| `chk_inventories_values` | CHECK (quantity >= 0 AND average_cost >= 0 AND alert_quantity >= 0) | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | لا يوجد `business_id` في هذا الجدول — الوصول إلى الـ business يتم عبر `warehouse_id`. هذا مقبول من ناحية التطبيع لكن يكسر نمط الـ Composite FK. **ليس حرجاً** لأن `warehouse_id` بالفعل scoped by business. |
| 2 | ✅ Pass | `quantity >= 0` يمنع الكميات السالبة — صحيح لنظام ERP يمنع البيع دون مخزون. |
| 3 | ℹ️ Info | لا يوجد `created_at` — مقبول لأن هذا جدول حالة (State table) وليس log. |

#### Verdict: ✅ APPROVED

---

### 3. `inventory_transactions` (Lines 570–597)

#### Attributes Review

| Column | Type | Verdict |
|--------|------|---------|
| `id` | CHAR(36) | ✅ |
| `business_id` | CHAR(36) NOT NULL | ✅ |
| `warehouse_id` | CHAR(36) NOT NULL | ✅ |
| `product_unit_id` | CHAR(36) NOT NULL | ✅ |
| `transaction_type` | ENUM('In','Out','Adjust') | ✅ |
| `quantity` | DECIMAL(18,3) NOT NULL | ✅ |
| `unit_cost` | DECIMAL(18,2) DEFAULT 0.00 | ✅ |
| `reference_type` | ENUM(...) | ✅ Polymorphic ref |
| `reference_id` | CHAR(36) NOT NULL | ✅ |
| `transaction_date` | TIMESTAMP | ✅ |

#### Reference Types

```
'SalesInvoice','SalesReturn','PurchaseInvoice','PurchaseReturn','Transfer','Adjustment'
```

✅ يغطي جميع حالات حركة المخزون.

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `fk_inv_tx_warehouse` | FK (business_id, warehouse_id) → warehouses(business_id, id) | ✅ Composite |
| `fk_inv_tx_product_unit` | FK (business_id, product_unit_id) → product_units(business_id, id) | ✅ Composite |
| `chk_inv_tx_values` | CHECK (quantity > 0 AND unit_cost >= 0) | ✅ |
| `idx_inv_tx_reference` | INDEX (reference_type, reference_id) | ✅ |
| `idx_inv_tx_date` | INDEX (transaction_date) | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | الجدول Immutable (لا يوجد `updated_at` أو `deleted_at`) — صحيح للـ Ledger. |
| 2 | ✅ Pass | `quantity > 0` (وليس >=) — الكمية المحولة دائماً موجبة، الاتجاه يُحدد بواسطة `transaction_type`. تصميم صحيح. |
| 3 | ✅ Pass | Polymorphic reference pattern مناسب — `reference_type` + `reference_id`. |

#### Verdict: ✅ APPROVED — تصميم ممتاز لـ Inventory Ledger.

---

### 4. `inventory_transfers` (Lines 603–631)

#### Attributes Review

جميع الحقول صحيحة ومناسبة.

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `uq_inventory_transfers_number` | UNIQUE (business_id, transfer_number) | ✅ |
| `uq_inventory_transfers_business_id_id` | UNIQUE (business_id, id) | ✅ |
| `fk_inv_transfer_from_wh` | FK (business_id, from_warehouse_id) → warehouses(business_id, id) RESTRICT | ✅ |
| `fk_inv_transfer_to_wh` | FK (business_id, to_warehouse_id) → warehouses(business_id, id) RESTRICT | ✅ |
| `fk_inv_transfer_created_by` | FK → users(id) RESTRICT | ✅ |
| `chk_different_transfer_warehouses` | CHECK (from_warehouse_id <> to_warehouse_id) | ✅ **ممتاز** — يمنع التحويل من وإلى نفس المخزن |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | التحقق من عدم تكرار المخزن (from ≠ to) على مستوى DB — ممتاز. |
| 2 | ✅ Pass | لا يوجد `deleted_at` في التحويلات — مقبول لأنها وثيقة مخزنية. |

#### Verdict: ✅ APPROVED

---

### 5. `inventory_transfer_items` (Lines 637–653)

#### Attributes Review

| Column | Type | Verdict |
|--------|------|---------|
| `id` | CHAR(36) | ✅ |
| `business_id` | CHAR(36) | ✅ |
| `transfer_id` | CHAR(36) | ✅ |
| `product_unit_id` | CHAR(36) | ✅ |
| `quantity` | DECIMAL(18,3) | ✅ |
| `unit_cost` | DECIMAL(18,2) DEFAULT 0.00 | ✅ |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| FK → inventory_transfers(business_id, id) CASCADE | ✅ |
| FK → product_units(business_id, id) RESTRICT | ✅ |
| CHECK (quantity > 0 AND unit_cost >= 0) | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | لا يوجد UNIQUE constraint على `(transfer_id, product_unit_id)` — يعني يمكن إضافة نفس المنتج مرتين في نفس التحويل. **اقتراح: إضافة UNIQUE**. |

#### Verdict: ✅ APPROVED

---

## 🏗️ Normalization Check

| NF | Status | Notes |
|----|--------|-------|
| 1NF | ✅ Pass | ✅ |
| 2NF | ✅ Pass | ✅ |
| 3NF | ✅ Pass | `inventories` هو state table — ليس denormalization |
| BCNF | ✅ Pass | ✅ |

---

## 📝 Consolidated Findings

| # | Table | Severity | Issue | Recommendation |
|---|-------|----------|-------|----------------|
| 1 | `inventories` | ⚠️ Minor | لا يوجد business_id | مقبول — يُستنتج من warehouse |
| 2 | `inventory_transfer_items` | ⚠️ Minor | لا يوجد UNIQUE (transfer_id, product_unit_id) | إضافة UNIQUE لمنع التكرار |

---

## ✅ Domain 4 Final Verdict

> ### 🟢 APPROVED
> 
> Domain 4 (INVENTORY) **جاهز للاعتماد**. التصميم قوي:
> - ✅ Warehouse default per branch (sentinel pattern)
> - ✅ Immutable inventory ledger
> - ✅ Transfer validation (from ≠ to)
> - ✅ AVCO cost tracking
> - ✅ Non-negative quantity enforcement
> 
> **لا توجد مشاكل حرجة.**

---

*يُتابع في التقرير التالي: Domain 5 — SALES*
