# SQLite Schema Extraction
## Phase 1 — Core ERP Foundation Tables
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`
**Date:** 2026-07-18

---

## 1. Table: `account_types`

### 1. General Information
- **Table Name:** `account_types`
- **Purpose:** Lookup table for chart of accounts classification (Assets, Liabilities, Equity, Revenue, Expenses).
- **Domain:** DOMAIN 0 — LOOKUP / REFERENCE
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint (auto-increment)` | No | `auto` | PK — standard integer, NOT UUID |
| `name_en` | `string` | No | — | English name |
| `name_ar` | `string` | No | — | Arabic name |
| `slug` | `string` | No | — | UNIQUE — e.g. assets, liabilities |
| `is_active` | `boolean` | No | `true` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (auto-increment bigint)
- **Foreign Keys:** None
- **Composite Keys:** None
- **Unique Constraints:** `slug`

### 4. Relationships
*غير موجودة في الوثيقة المرجعية (No explicit relationships defined).*

### 5. Indexes
- **Unique Indexes:** `slug`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `name_en`, `name_ar`, `slug`, `is_active`
- **UNIQUE Constraints:** `slug`
- **DEFAULT Constraints:** `is_active` = `true`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `bigint (auto-increment)` | `INTEGER` | `IntColumn` |
| `string` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** لا يحتاج إضافة الأعمدة (`sync_status`, `version`, `device_id`).
- **السبب:** هذا الجدول هو جدول مرجعي (Lookup Table) يُقرأ فقط (Read-Only) ويتم سحبه من الخادم إلى التطبيق المحلي. لا يتم إنشاء أو تعديل بياناته محلياً، لذا لا يتطلب أعمدة تعقب المزامنة الخاصة بـ Offline-First.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 2. Table: `system_settings`

### 1. General Information
- **Table Name:** `system_settings`
- **Purpose:** Key-value system configuration store per business with JSONB type-safe storage.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `setting_key` | `string(100)` | No | — | |
| `setting_value` | `jsonb` | Yes | — | JSONB data structure |
| `setting_type` | `string(20)` | No | `'string'` | CHECK: string, integer, boolean, json |
| `is_public` | `boolean` | No | `false` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, setting_key)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `system_settings` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, setting_key)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `setting_key`, `setting_type`, `is_public`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, setting_key)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `setting_type` = `'string'`, `is_public` = `false`
- **CHECK Constraints:** `chk_ss_type`

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` | `TEXT` | `TextColumn` |
| `string(20)` | `TEXT` | `TextColumn` |
| `jsonb` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج إضافة الأعمدة.
- **السبب:** الجدول تفاعلي ومحوري في تشغيل الفروع. إعدادات النظام يمكن تعديلها محلياً ومزامنتها سحابياً (Bidirectional)، مما يتطلب تعقب حالة المزامنة وفض النزاعات.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 3. Table: `print_settings`

### 1. General Information
- **Table Name:** `print_settings`
- **Purpose:** Document printing and layout configurations per business or specific branch.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `branch_id` | `uuid` | Yes | — | Composite FK (NULL = global business setting) |
| `document_type` | `string(50)` | No | — | e.g. SalesInvoice, Receipt |
| `template_name` | `string(100)` | No | `'default'` | |
| `header_text` | `text` | Yes | — | |
| `footer_text` | `text` | Yes | — | |
| `show_logo` | `boolean` | No | `true` | |
| `show_tax_summary` | `boolean` | No | `true` | |
| `show_qr_code` | `boolean` | No | `true` | |
| `paper_size` | `string(20)` | No | `'A4'` | CHECK: A4, A5, Thermal80mm, Thermal58mm |
| `margin_top` | `integer` | No | `10` | |
| `margin_bottom` | `integer` | No | `10` | |
| `margin_left` | `integer` | No | `10` | |
| `margin_right` | `integer` | No | `10` | |
| `font_size` | `integer` | No | `12` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), `(business_id, branch_id)` → `branches(business_id, id)` (CASCADE)
- **Composite Keys:** `(business_id, branch_id)`
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `print_settings` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `branches` | `print_settings` | `belongsTo` | `branch_id` | `CASCADE` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `document_type`, `template_name`, `show_logo`, `show_tax_summary`, `show_qr_code`, `paper_size`, `margin_top`, `margin_bottom`, `margin_left`, `margin_right`, `font_size`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `template_name` = `'default'`, `show_logo` = `true`, `show_tax_summary` = `true`, `show_qr_code` = `true`, `paper_size` = `'A4'`, `margin_top` = `10`, `margin_bottom` = `10`, `margin_left` = `10`, `margin_right` = `10`, `font_size` = `12`
- **CHECK Constraints:** `chk_ps_paper_size`

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(100)` / `(20)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `integer` | `INTEGER` | `IntColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج إضافة الأعمدة.
- **السبب:** إعدادات الطباعة تخص الفروع وتعدل محلياً، وتحتاج مزامنة (Bidirectional) مع السحابة لتطبيقها على أجهزة ونقاط البيع الأخرى في نفس الفرع.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 4. Table: `sequences`

### 1. General Information
- **Table Name:** `sequences`
- **Purpose:** Sequential document numbering generators (e.g., INV-2026-00001) per business and branch.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `branch_id` | `uuid` | Yes | — | Composite FK (NULL = business-wide) |
| `document_type` | `string(50)` | No | — | e.g., SalesInvoice, PurchaseInvoice |
| `prefix` | `string(20)` | Yes | — | |
| `suffix` | `string(20)` | Yes | — | |
| `current_value` | `bigint` | No | `0` | CHECK: >= 0 |
| `step` | `integer` | No | `1` | CHECK: > 0 |
| `padding` | `integer` | No | `5` | CHECK: > 0 |
| `reset_frequency` | `string(20)` | No | `'Never'` | CHECK: Never, Daily, Monthly, Yearly |
| `last_reset_date` | `date` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), `(business_id, branch_id)` → `branches(business_id, id)` (CASCADE)
- **Composite Keys:** `(business_id, branch_id)`
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
*غير موجودة بشكل صريح في الموديل (No dedicated model explicitly defined in model scan)، ولكن ضمنياً:*
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `sequences` | `Implicit` | `business_id` | `CASCADE` | *غير محدد* |
| `branches` | `sequences` | `Implicit` | `branch_id` | `CASCADE` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `document_type`, `current_value`, `step`, `padding`, `reset_frequency`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `current_value` = `0`, `step` = `1`, `padding` = `5`, `reset_frequency` = `'Never'`
- **CHECK Constraints:** `chk_seq_val` (`current_value >= 0`), `chk_seq_step` (`> 0`), `chk_seq_pad` (`> 0`), `chk_seq_reset`

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(20)` | `TEXT` | `TextColumn` |
| `bigint` | `INTEGER` | `IntColumn` |
| `integer` | `INTEGER` | `IntColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** لا يحتاج إضافة الأعمدة.
- **السبب:** هذا الجدول מدار حصرياً بشكل محلي (Local Only) ولا يتم مزامنته إطلاقاً إلى السحابة، وذلك لمنع تعارض الأرقام التسلسلية للفواتير والقيود بين الأجهزة المختلفة (Offline-First Rule).

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## Final Verification Report

- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

**Ready For Drift Generation — Phase 1 ✅**
