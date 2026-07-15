# 🔍 Database Audit Report — Domain 3: CATALOG

**Schema:** Smart Merchant ERP v2.1  
**Date:** 2026-07-11  
**Domain Scope:** Lines 308–502

---

## 📋 Domain Overview

| # | Entity | Type | Lines | Description |
|---|--------|------|-------|-------------|
| 1 | `categories` | Master | 318–338 | Product categories (tree hierarchy) |
| 2 | `brands` | Master | 344–360 | Product brands per business |
| 3 | `units` | Master | 366–376 | Global units of measure |
| 4 | `products` | Master | 382–408 | Core product definitions |
| 5 | `product_units` | Master | 414–452 | Units, barcodes, prices per product |
| 6 | `branch_product_prices` | Override | 458–483 | Branch-specific price overrides |
| 7 | `product_images` | Detail | 489–502 | Product image gallery |

**Total Entities in Domain: 7**

---

## 🔬 Entity-by-Entity Audit

---

### 1. `categories` (Lines 318–338)

#### Attributes Review

| Column | Type | Nullable | Default | Verdict |
|--------|------|----------|---------|---------|
| `id` | CHAR(36) | NOT NULL | UUID() | ✅ |
| `business_id` | CHAR(36) | NOT NULL | — | ✅ Multi-tenant scope |
| `parent_id` | CHAR(36) | NULL | — | ✅ Self-referencing for tree |
| `category_name` | VARCHAR(100) | NOT NULL | — | ✅ |
| `description` | TEXT | NULL | — | ✅ |
| `image_path` | VARCHAR(500) | NULL | — | ✅ |
| `is_active` | BOOLEAN | NOT NULL | TRUE | ✅ |
| `created_at` | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | ✅ |
| `updated_at` | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP ON UPDATE | ✅ |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_categories` | PK (id) | ✅ |
| `uq_categories_business_name` | UNIQUE (business_id, category_name) | ✅ |
| `uq_categories_business_id_id` | UNIQUE (business_id, id) | ✅ Composite ref key |
| `fk_categories_business` | FK → businesses(id) RESTRICT | ✅ |
| `fk_categories_parent` | FK → categories(id) RESTRICT | ✅ Self-ref |
| `idx_categories_business_id` | INDEX | ✅ |
| `idx_categories_parent_id` | INDEX | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | `uq_categories_business_name` يمنع تكرار اسم الفئة في نفس المستوى وفي جميع المستويات. هذا قد يكون مقيداً — مثلاً لا يمكن وجود "أجهزة إلكترونية" تحت "منتجات" و "أجهزة إلكترونية" تحت "مستلزمات" في نفس الأعمال. **القرار**: هذا سلوك مقصود عادةً في أنظمة ERP لتجنب الالتباس. ✅ مقبول. |
| 2 | ⚠️ Minor | `fk_categories_parent` يشير إلى `categories(id)` بدلاً من `categories(business_id, id)` — هذا يعني نظرياً يمكن أن يكون الـ parent من business آخر. **لكن**: بما أن category_name unique per business_id، فالأثر العملي ضعيف جداً لأن الوصول يكون دائماً filtered by business_id. **اقتراح**: تعديل FK لتكون `FOREIGN KEY (business_id, parent_id) REFERENCES categories(business_id, id)` لضمان أمان أكبر. |

#### Verdict: ⚠️ APPROVED WITH NOTE — FK الـ parent يجب أن يكون composite.

---

### 2. `brands` (Lines 344–360)

#### Attributes Review

جميع الحقول صحيحة ومناسبة.

#### Constraints Review

| Constraint | Verdict |
|-----------|---------|
| PK, UNIQUE business+name, FK business, composite ref key | ✅ All correct |

#### Findings

لا توجد مشاكل. التصميم مطابق لنمط `categories`.

#### Verdict: ✅ APPROVED

---

### 3. `units` (Lines 366–376)

#### Attributes Review

| Column | Type | Nullable | Verdict |
|--------|------|----------|---------|
| `id` | CHAR(36) | NOT NULL | ✅ |
| `unit_name` | VARCHAR(100) | NOT NULL | ✅ |
| `unit_symbol` | VARCHAR(10) | NOT NULL | ✅ |
| `unit_description` | TEXT | NULL | ✅ |
| `created_at` | TIMESTAMP | NOT NULL | ✅ |
| `updated_at` | TIMESTAMP | NOT NULL | ✅ |

#### Constraints Review

| Constraint | Verdict |
|-----------|---------|
| `pk_units` PK | ✅ |
| `uq_units_symbol` UNIQUE (unit_symbol) | ✅ Global uniqueness |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ℹ️ Design | الوحدات (`units`) هي System-level (ليست per-business). هذا تصميم مقصود — نفس الوحدات تُستخدم عبر جميع الأعمال. ✅ مقبول ومنطقي. |
| 2 | ⚠️ Minor | لا يوجد UNIQUE على `unit_name` — يمكن إنشاء وحدتين بنفس الاسم لكن رمز مختلف. **اقتراح: إضافة UNIQUE (unit_name)**. |

#### Verdict: ✅ APPROVED

---

### 4. `products` (Lines 382–408)

#### Attributes Review

| Column | Type | Nullable | Default | Verdict |
|--------|------|----------|---------|---------|
| `id` | CHAR(36) | NOT NULL | UUID() | ✅ |
| `business_id` | CHAR(36) | NOT NULL | — | ✅ |
| `category_id` | CHAR(36) | NULL | — | ✅ Optional |
| `brand_id` | CHAR(36) | NULL | — | ✅ Optional |
| `product_code` | VARCHAR(100) | NOT NULL | — | ✅ |
| `product_name` | VARCHAR(255) | NOT NULL | — | ✅ |
| `description` | TEXT | NULL | — | ✅ |
| `is_active` | BOOLEAN | NOT NULL | TRUE | ✅ |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | — | — | ✅ |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_products` | PK (id) | ✅ |
| `uq_products_code` | UNIQUE (business_id, product_code) | ✅ |
| `uq_products_business_id_id` | UNIQUE (business_id, id) | ✅ |
| `fk_products_business` | FK → businesses(id) | ✅ |
| `fk_products_category` | **FK (business_id, category_id) → categories(business_id, id)** | ✅ **ممتاز** — Composite FK يضمن أن الفئة تنتمي لنفس الأعمال |
| `fk_products_brand` | **FK (business_id, brand_id) → brands(business_id, id)** | ✅ **ممتاز** — نفس النمط |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | استخدام Composite FK ممتاز — يضمن أن كل من `category_id` و `brand_id` ينتميان لنفس الـ business. هذا نمط متقدم ومحكم. |
| 2 | ✅ Pass | Soft delete via `deleted_at` ✅ |

#### Verdict: ✅ APPROVED — تصميم ممتاز.

---

### 5. `product_units` (Lines 414–452)

#### Attributes Review

| Column | Type | Verdict |
|--------|------|---------|
| `id` | CHAR(36) | ✅ |
| `business_id` | CHAR(36) | ✅ |
| `product_id` | CHAR(36) | ✅ |
| `unit_id` | CHAR(36) | ✅ |
| `sku` | VARCHAR(100) NULL | ✅ |
| `barcode` | VARCHAR(100) NULL | ✅ |
| `conversion_factor` | DECIMAL(18,4) DEFAULT 1.0000 | ✅ |
| `purchase_price` | DECIMAL(18,2) DEFAULT 0.00 | ✅ |
| `selling_price` | DECIMAL(18,2) DEFAULT 0.00 | ✅ |
| `minimum_price` | DECIMAL(18,2) DEFAULT 0.00 | ✅ |
| `is_base_unit` | BOOLEAN DEFAULT FALSE | ✅ |
| `base_unit_product_id` | CHAR(36) NULL | ✅ Sentinel column |
| `is_active` | BOOLEAN DEFAULT TRUE | ✅ |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `uq_product_units_business_barcode` | UNIQUE (business_id, barcode) | ✅ No duplicate barcodes per business |
| `uq_product_units_business_sku` | UNIQUE (business_id, sku) | ✅ No duplicate SKUs |
| `uq_product_units_one_base` | UNIQUE (base_unit_product_id) | ✅ One base unit per product (via sentinel) |
| `fk_product_units_product` | FK (business_id, product_id) → products(business_id, id) | ✅ Composite FK |
| `fk_product_units_unit` | FK → units(id) | ✅ |
| `chk_product_units_conversion` | CHECK (conversion_factor > 0) | ✅ |
| `chk_product_units_prices` | CHECK (purchase_price >= 0 AND selling_price >= minimum_price AND minimum_price >= 0) | ✅ **ممتاز** |

#### Triggers

| Trigger | Purpose | Verdict |
|---------|---------|---------|
| `trg_product_units_base_bi/bu` | Sets `base_unit_product_id` sentinel | ✅ |
| `trg_products_require_base_unit_bi` | First unit must be base | ✅ |
| `trg_products_require_base_unit_bu` | Can't unset last base unit | ✅ |
| `trg_products_require_base_unit_bd` | Can't delete last base unit | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | نمط `base_unit_product_id` sentinel + UNIQUE constraint هو حل ذكي لمشكلة "وحدة أساسية واحدة فقط لكل منتج" في MySQL. |
| 2 | ✅ Pass | التحقق `selling_price >= minimum_price` يمنع البيع بأقل من الحد الأدنى. |
| 3 | ⚠️ Minor | لا يوجد UNIQUE constraint على `(product_id, unit_id)` — يعني يمكن إضافة نفس الوحدة مرتين لنفس المنتج. **اقتراح: إضافة UNIQUE (product_id, unit_id)**. |

#### Verdict: ✅ APPROVED — مع اقتراح إضافة UNIQUE (product_id, unit_id).

---

### 6. `branch_product_prices` (Lines 458–483)

#### Attributes Review

جميع الحقول صحيحة. توفر تجاوز أسعار على مستوى الفرع.

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `uq_branch_product_prices` | UNIQUE (branch_id, product_unit_id) | ✅ Override واحد لكل فرع-وحدة منتج |
| `fk_branch_product_prices_branch` | FK (business_id, branch_id) → branches(business_id, id) | ✅ Composite |
| `fk_branch_product_prices_product_unit` | FK (business_id, product_unit_id) → product_units(business_id, id) | ✅ Composite |
| `chk_branch_product_prices` | Same price validation as product_units | ✅ |

#### Verdict: ✅ APPROVED — تصميم سليم ومحكم.

---

### 7. `product_images` (Lines 489–502)

#### Attributes Review

| Column | Type | Verdict |
|--------|------|---------|
| `id` | CHAR(36) | ✅ |
| `product_id` | CHAR(36) NOT NULL | ✅ |
| `image_path` | VARCHAR(500) NOT NULL | ✅ |
| `is_primary` | BOOLEAN DEFAULT FALSE | ✅ |
| `primary_product_id` | CHAR(36) NULL | ✅ Sentinel |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `uq_product_images_primary` | UNIQUE (primary_product_id) | ✅ One primary per product |
| `fk_product_images_product` | FK → products(id) CASCADE | ✅ |

#### Triggers

- `trg_product_images_primary_bi/bu` — Manages `primary_product_id` sentinel ✅

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | لا يوجد `business_id` في هذا الجدول — FK يشير إلى `products(id)` مباشرة بدلاً من Composite FK. هذا آمن لأن `product_id` يكفي للوصول، لكنه يكسر نمط الـ Composite FK المستخدم في باقي الجداول. **ليس حرجاً** لكن يكسر الاتساق. |

#### Verdict: ✅ APPROVED

---

## 🏗️ Normalization Check

| NF | Status | Notes |
|----|--------|-------|
| 1NF | ✅ Pass | جميع القيم atomic |
| 2NF | ✅ Pass | لا توجد تبعيات جزئية |
| 3NF | ✅ Pass | لا توجد تبعيات انتقالية |
| BCNF | ✅ Pass | ✅ |

**ملاحظة**: الأسعار مكررة في `product_units` و `branch_product_prices` — لكن هذا **ليس denormalization** بل هو **override pattern** (السعر الافتراضي + التجاوز على مستوى الفرع). تصميم صحيح.

---

## 📝 Consolidated Findings

| # | Table | Severity | Issue | Recommendation |
|---|-------|----------|-------|----------------|
| 1 | `categories` | ⚠️ Medium | FK parent يشير إلى id فقط | تعديل إلى Composite FK `(business_id, parent_id)` |
| 2 | `units` | ⚠️ Minor | لا يوجد UNIQUE على unit_name | إضافة UNIQUE |
| 3 | `product_units` | ⚠️ Minor | لا يوجد UNIQUE على (product_id, unit_id) | إضافة UNIQUE لمنع التكرار |
| 4 | `product_images` | ⚠️ Minor | لا يوجد business_id (يكسر نمط Composite FK) | مقبول — ليس حرجاً |

---

## ✅ Domain 3 Final Verdict

> ### 🟢 APPROVED
> 
> Domain 3 (CATALOG) **جاهز للاعتماد**. التصميم قوي بشكل خاص:
> - ✅ Composite FKs لضمان Business-scope isolation
> - ✅ Base Unit sentinel pattern
> - ✅ Comprehensive price validation
> - ✅ Tree hierarchy for categories
> - ✅ Branch-level price override pattern
> 
> **المشكلة الوحيدة التي تحتاج اهتمام**: FK الـ parent في `categories` يجب أن يكون composite.
> 
> **لا توجد مشاكل حرجة (Critical).**

---

*يُتابع في التقرير التالي: Domain 4 — INVENTORY*
