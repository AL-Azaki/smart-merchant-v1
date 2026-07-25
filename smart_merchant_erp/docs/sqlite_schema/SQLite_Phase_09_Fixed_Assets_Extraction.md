# SQLite Schema Extraction
## Phase 9 — Fixed Assets & Depreciation
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`
**Date:** 2026-07-18

---

## Architecture Compliance & Single Source of Truth Mandate

> [!IMPORTANT]
> **Single Source of Truth Mandate for Fixed Assets & Depreciation:**
> تطبيق **Flutter SQLite ERP** هو المصدر الرسمي والوحيد (Single Source of Truth) لجميع بيانات الأصول الثابتة، وتشمل:
> (تعريف الأصول الثابتة، تصنيف الأصول، بيانات الاقتناء، العمر الإنتاجي، القيمة المتبقية، جداول الإهلاك، وقيود الإهلاك المرجعية). جميع عمليات إنشاء وتعديل وإدارة بيانات الأصول تتم محلياً داخل SQLite.
> 
> **مسؤولية Laravel PostgreSQL:**  
> ليس مسؤولاً عن إنشاء أو تعديل بيانات الأصول الثابتة أو تنفيذ حساب الإهلاك، وتقتصر مسؤوليته فقط على: استقبال البيانات بعد المزامنة، التقارير المركزية، لوحة التحكم Dashboard، التحليلات، وحفظ النسخة السحابية.
>
> **اتجاه المزامنة الرسمي:**  
> `Flutter SQLite ERP` → `Sync Engine` → `Laravel PostgreSQL` → `Dashboard / Reporting`
> 
> عند ظهور جداول سبق استخراجها أو جداول خارجية في العلاقات (`businesses`, `branches`, `users`, `chart_of_accounts`, `journal_entries`, `journal_entry_lines`, `accounting_periods`, `fiscal_years`, `currencies`, `departments`, `employees` إلخ)، يتم توثيق العلاقة فقط كمرجع دون إعادة استخراجها أو نسخ أعمدتها.

---

## 1. Table: `fixed_assets`

### 1. General Information
- **Table Name:** `fixed_assets`
- **Purpose:** Fixed assets register tracking acquisition, useful life, and depreciation methods.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (Fixed Assets)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (RESTRICT) |
| `branch_id` | `uuid` | Yes | — | Composite FK |
| `asset_category_id`| `uuid` | Yes | — | FK |
| `currency_id` | `uuid` | No | — | FK → currencies (RESTRICT) |
| `asset_code` | `string(50)` | No | — | |
| `asset_name` | `string(255)` | No | — | |
| `acquisition_date` | `date` | No | — | |
| `acquisition_cost` | `decimal(18,2)` | No | — | CHECK: >= 0 |
| `base_acquisition_cost`| `decimal(18,2)`| No | — | CHECK: >= 0 |
| `useful_life` | `integer` | No | — | CHECK: > 0 (in periods/months) |
| `residual_value` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `base_residual_value`| `decimal(18,2)`| No | `0.00` | CHECK: >= 0 |
| `depreciation_method`| `string(50)` | No | — | e.g. StraightLine |
| `depreciation_start_date`| `date` | No | — | |
| `status` | `string(30)` | No | `'Draft'` | CHECK: Draft, Active, Depreciating, Fully Depreciated, Disposed |
| `responsible_user_id`| `uuid`| Yes | — | FK → users (SET NULL) |
| `created_by` | `uuid` | No | — | FK → users (RESTRICT) |
| `updated_by` | `uuid` | Yes | — | FK → users (SET NULL) |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `created_by` → `users.id` (RESTRICT), `updated_by` → `users.id` (SET NULL), `responsible_user_id` → `users.id` (SET NULL), composite `(business_id, branch_id)` → `branches` (RESTRICT).  
  *(ملاحظة مرجعية: `asset_category_id` يُشار إليه كـ FK في تعريف الجدول ليربط الأصل بتصنيفه).*
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, asset_code)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `fixed_assets` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `branches` | `fixed_assets` | `belongsTo` | `branch_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `fixed_assets` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `fixed_assets` | `belongsTo` | `responsible_user_id` / `created_by` / `updated_by` | `SET NULL` / `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `DepreciationSchedule` (`depreciationSchedules`)).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, asset_code)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `currency_id`, `asset_code`, `asset_name`, `acquisition_date`, `acquisition_cost`, `base_acquisition_cost`, `useful_life`, `residual_value`, `base_residual_value`, `depreciation_method`, `depreciation_start_date`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, asset_code)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `residual_value` = `0.00`, `base_residual_value` = `0.00`, `status` = `'Draft'`
- **CHECK Constraints:** `chk_fa_status` (`status IN ('Draft', 'Active', 'Depreciating', 'Fully Depreciated', 'Disposed')`), `chk_fa_cost` (`acquisition_cost >= 0, base_acquisition_cost >= 0`), `chk_fa_life` (`useful_life > 0`), `chk_fa_residual` (`residual_value >= 0, base_residual_value >= 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(255)` / `(30)` | `TEXT` | `TextColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `integer` | `INTEGER` | `IntColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** بيانات وتصنيفات وحالة الأصول الثابتة وتفاصيل اقتنائها تُسجل وتُدار محلياً داخل نظام الـ ERP كمرجع للأصول، وتتطلب الرفع والمزامنة مع السحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 2. Table: `depreciation_schedules`

### 1. General Information
- **Table Name:** `depreciation_schedules`
- **Purpose:** Periodic depreciation schedule entries for fixed assets over their useful life.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (Fixed Assets)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `fixed_asset_id` | `uuid` | No | — | Composite FK |
| `depreciation_period`| `integer` | No | — | Period number |
| `scheduled_posting_date`| `date` | No | — | |
| `depreciation_amount`| `decimal(18,2)`| No | — | CHECK: >= 0 |
| `base_depreciation_amount`| `decimal(18,2)`| No| — | CHECK: >= 0 |
| `accumulated_depreciation`| `decimal(18,2)`| No| — | |
| `base_accumulated_depreciation`| `decimal(18,2)`| No| — | |
| `remaining_book_value`| `decimal(18,2)`| No| — | |
| `base_remaining_book_value`| `decimal(18,2)`| No| — | |
| `status` | `string(30)` | No | `'Pending'` | CHECK: Pending, Ready, Posted, Cancelled |
| `created_by` | `uuid` | No | — | FK → users (RESTRICT) |
| `updated_by` | `uuid` | Yes | — | FK → users (SET NULL) |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** composite `(business_id, fixed_asset_id)` → `fixed_assets` (CASCADE), `created_by` → `users.id` (RESTRICT), `updated_by` → `users.id` (SET NULL)
- **Composite Keys:** None
- **Unique Constraints:** `uq_dep_schedule_period` on `(business_id, fixed_asset_id, depreciation_period)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `fixed_assets` | `depreciation_schedules`| `belongsTo` | `fixed_asset_id` | `CASCADE` | *غير محدد* |
| `users` | `depreciation_schedules`| `belongsTo` | `created_by` / `updated_by` | `RESTRICT` / `SET NULL`| *غير محدد* |

*(Note: Associated composite with `businesses` via `business_id`).*

### 5. Indexes
- **Unique Indexes:** `uq_dep_schedule_period` on `(business_id, fixed_asset_id, depreciation_period)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `fixed_asset_id`, `depreciation_period`, `scheduled_posting_date`, `depreciation_amount`, `base_depreciation_amount`, `accumulated_depreciation`, `base_accumulated_depreciation`, `remaining_book_value`, `base_remaining_book_value`, `status`, `created_by`
- **UNIQUE Constraints:** `uq_dep_schedule_period` on `(business_id, fixed_asset_id, depreciation_period)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `status` = `'Pending'`
- **CHECK Constraints:** `chk_ds_status` (`status IN ('Pending', 'Ready', 'Posted', 'Cancelled')`), `chk_ds_amount` (`depreciation_amount >= 0, base_depreciation_amount >= 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `integer` | `INTEGER` | `IntColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `string(30)` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** جداول الإهلاك الدورية وتغير حالاتها (`Pending`, `Ready`, `Posted`) تُدار محلياً في الـ ERP وترتبط بقيود الإهلاك المحاسبية، وتتطلب المزامنة مع الخادم.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## Final Verification Report

- Fixed Assets Tables ...... PASS
- Columns Extraction ....... PASS
- Relationships ............ PASS
- Constraints .............. PASS
- Type Mapping ............. PASS
- SQLite Compatibility ..... PASS
- Architecture Compliance .. PASS

**Ready For Drift Generation — Phase 9 ✅**
