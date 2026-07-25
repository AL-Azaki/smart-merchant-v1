# SQLite Schema Extraction
## Phase 10 — System Administration & Supporting Modules
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`
**Date:** 2026-07-18

---

## Architecture Compliance & Single Source of Truth Mandate

> [!IMPORTANT]
> **Single Source of Truth Mandate for System Administration & Supporting Modules:**
> تطبيق **Flutter SQLite ERP** هو المصدر الرسمي والوحيد (Single Source of Truth) لجميع بيانات الإدارة العامة والوحدات المساندة، وتشمل:
> (المصروفات، تصنيفات المصروفات، المرفقات، أسعار الصرف، وسجلات النشاط). جميع عمليات إنشاء وتعديل وإدارة هذه البيانات تتم محلياً داخل SQLite.
> 
> **مسؤولية Laravel PostgreSQL:**  
> ليس مسؤولاً عن إنشاء أو تعديل هذه البيانات، وتقتصر مسؤوليته فقط على: استقبال البيانات بعد المزامنة، التقارير، لوحة التحكم Dashboard، التحليلات، وحفظ النسخة السحابية. ولا يتم إنشاء أو تعديل أي سجل من هذه الوحدات داخل Laravel.
>
> **اتجاه المزامنة الرسمي:**  
> `Flutter SQLite ERP` → `Sync Engine` → `Laravel PostgreSQL` → `Dashboard / Reporting`
> 
> عند ظهور جداول سبق استخراجها أو جداول خارجية في العلاقات (`businesses`, `branches`, `users`, `currencies`, `chart_of_accounts`, `journal_entries`, `payments`, `suppliers`, `customers`, `employees`, `fixed_assets`, `system_settings`, `print_settings`, `sequences` إلخ)، يتم توثيق العلاقة فقط كمرجع دون إعادة استخراجها أو نسخ أعمدتها.

---

## 1. Table: `expense_categories`

### 1. General Information
- **Table Name:** `expense_categories`
- **Purpose:** Expense classification categories linked to chart of accounts.
- **Domain:** DOMAIN 7 — FINANCE (Expenses)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `chart_of_account_id`| `uuid` | No | — | Composite FK |
| `category_name` | `string(100)` | No | — | |
| `description` | `text` | Yes | — | |
| `is_active` | `boolean` | No | `true` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), composite `(business_id, chart_of_account_id)` → `chart_of_accounts` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, category_name)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `expense_categories`| `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `chart_of_accounts`| `expense_categories`| `belongsTo` | `chart_of_account_id`| `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `Expense`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, category_name)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `chart_of_account_id`, `category_name`, `is_active`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, category_name)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `is_active` = `true`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تصنيفات المصروفات تُدار وتُعرّف محلياً في نظام الـ ERP وتُستخدم عبر جميع الصناديق لتوجيه المدفوعات والمصروفات، وتتطلب المزامنة مع الخادم.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 2. Table: `expenses`

### 1. General Information
- **Table Name:** `expenses`
- **Purpose:** Individual expense records with category, payment method, and multi-currency support.
- **Domain:** DOMAIN 7 — FINANCE (Expenses)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `branch_id` | `uuid` | No | — | Composite FK |
| `expense_category_id`| `uuid` | No | — | Composite FK |
| `expense_number` | `string(50)` | No | — | |
| `expense_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `payment_method_id`| `uuid` | No | — | Composite FK |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `exchange_rate` | `decimal(18,8)` | No | `1.00000000` | |
| `amount` | `decimal(18,2)` | No | — | |
| `base_amount` | `decimal(18,2)` | No | — | |
| `tax_amount` | `decimal(18,2)` | No | `0.00` | |
| `reference_number` | `string(100)` | Yes | — | |
| `status` | `string(20)` | No | `'Draft'` | CHECK: Draft, Posted, Cancelled |
| `notes` | `text` | Yes | — | |
| `created_by` | `uuid` | No | — | FK → users |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |
| `deleted_at` | `timestamp` | Yes | — | Soft Delete |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `created_by` → `users.id` (RESTRICT), composite `(business_id, branch_id)` → `branches`, composite `(business_id, expense_category_id)` → `expense_categories`, composite `(business_id, payment_method_id)` → `payment_methods`
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, expense_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `expenses` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `branches` | `expenses` | `belongsTo` | `branch_id` | *غير محدد* | *غير محدد* |
| `expense_categories`| `expenses`| `belongsTo` | `expense_category_id`| *غير محدد* | *غير محدد* |
| `payment_methods`| `expenses` | `belongsTo` | `payment_method_id`| *غير محدد* | *غير محدد* |
| `currencies` | `expenses` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `expenses` | `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

*(Note: Associated with `attachments` via polymorphic relationship).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, expense_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `branch_id`, `expense_category_id`, `expense_number`, `expense_date`, `payment_method_id`, `currency_id`, `exchange_rate`, `amount`, `base_amount`, `tax_amount`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, expense_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `expense_date` = `CURRENT_TIMESTAMP`, `exchange_rate` = `1.00000000`, `tax_amount` = `0.00`, `status` = `'Draft'`
- **CHECK Constraints:** `chk_exp_status` (`status IN ('Draft', 'Posted', 'Cancelled')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(100)` / `(20)` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |
| `decimal(18,8)` / `(18,2)` | `REAL` | `RealColumn` |
| `text` | `TEXT` | `TextColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تسجيل المصروفات اليومية يتم محلياً في نقاط البيع والفروع ويؤدي لخصم المبالغ من الصناديق النقدية والحسابات، ويتطلب الرفع الفوري للمزامنة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 3. Table: `activity_logs`

### 1. General Information
- **Table Name:** `activity_logs`
- **Purpose:** System audit trail and activity log tracking user actions across entities.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (System Administration & Logs)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `user_id` | `uuid` | Yes | — | FK → users (SET NULL) |
| `action` | `string(100)` | No | — | e.g. create, update, post, reverse |
| `entity_type` | `string(50)` | No | — | Polymorphic |
| `entity_id` | `uuid` | Yes | — | Polymorphic |
| `details` | `jsonb` | Yes | — | JSONB delta or context |
| `ip_address` | `string(45)` | Yes | — | |
| `created_at` | `timestamp` | No | `CURRENT_TIMESTAMP` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), `user_id` → `users.id` (SET NULL)
- **Composite Keys:** None
- **Unique Constraints:** None

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `activity_logs` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `users` | `activity_logs` | `belongsTo` | `user_id` | `SET NULL` | *غير محدد* |

*(Note: Polymorphic entity tracking to any model via `entity_type`, `entity_id`).*

### 5. Indexes
- **Indexes:** `idx_activity_logs_lookup` on `(business_id, entity_type, entity_id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `action`, `entity_type`, `created_at`
- **UNIQUE Constraints:** None
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `created_at` = `CURRENT_TIMESTAMP`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` / `(50)` / `(45)` | `TEXT` | `TextColumn` |
| `jsonb` | `TEXT` | `TextColumn (JSON String)` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** حركات الموظفين وسجلات التدقيق والأمان (`audit trail`) تُسجل محلياً عند حدوث كل عملية على الجهاز، وتتطلب الرفع الدامغ إلى الخادم لأغراض الرقابة المركزية وتتبع النشاط.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 4. Table: `attachments`

### 1. General Information
- **Table Name:** `attachments`
- **Purpose:** Polymorphic file attachments across all business entities (invoices, contracts, expenses, etc.).
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (Supporting Modules & Attachments)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `entity_type` | `string(50)` | No | — | Polymorphic |
| `entity_id` | `uuid` | No | — | Polymorphic |
| `file_path` | `string(500)` | No | — | |
| `file_name` | `string(255)` | No | — | |
| `upload_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE)
- **Composite Keys:** None
- **Unique Constraints:** None

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `attachments` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |

*(Note: Polymorphic relationship `entity()` (`morphTo`) pointing to any model).*

### 5. Indexes
- **Indexes:** `idx_attachments_entity` on `(business_id, entity_type, entity_id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `entity_type`, `entity_id`, `file_path`, `file_name`, `upload_date`
- **UNIQUE Constraints:** None
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `upload_date` = `CURRENT_TIMESTAMP`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(500)` / `(255)` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** أرشفة المرفقات وإرفاق صور الفواتير أو العقود أو الإيصالات تتم محلياً عند إدخال الحركات، ويجب مزامنة هذه السجلات والمرفقات مع الخادم.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 5. Table: `exchange_rates`

### 1. General Information
- **Table Name:** `exchange_rates`
- **Purpose:** Historical exchange rates between currencies per business.
- **Domain:** DOMAIN 4 — FINANCE (Currencies & Exchange Rates)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `source_currency_id`| `uuid` | No | — | FK → currencies |
| `target_currency_id`| `uuid` | No | — | FK → currencies |
| `effective_date` | `date` | No | — | |
| `rate` | `decimal(20,8)` | No | — | CHECK: > 0 |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `source_currency_id` → `currencies.id` (RESTRICT), `target_currency_id` → `currencies.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `uq_exchange_rates_date` on `(business_id, source_currency_id, target_currency_id, effective_date)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `exchange_rates`| `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `exchange_rates`| `belongsTo` (Source)| `source_currency_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `exchange_rates`| `belongsTo` (Target)| `target_currency_id` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `uq_exchange_rates_date` on `(business_id, source_currency_id, target_currency_id, effective_date)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `source_currency_id`, `target_currency_id`, `effective_date`, `rate`
- **UNIQUE Constraints:** `(business_id, id)`, `uq_exchange_rates_date` on `(business_id, source_currency_id, target_currency_id, effective_date)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`
- **CHECK Constraints:** `chk_er_diff_currencies` (`source_currency_id <> target_currency_id`), `chk_er_rate_positive` (`rate > 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `decimal(20,8)` | `REAL` | `RealColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** أسعار الصرف اليومية والتاريخية هي المرجع لحساب الفواتير وتحويل العملات الأجنبية في جميع الحركات المحلية في SQLite، وتتطلب المزامنة مع السحابة والأجهزة التابعة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## Final Verification Report

- Supporting Tables ........ PASS
- Columns Extraction ....... PASS
- Relationships ............ PASS
- Constraints .............. PASS
- Type Mapping ............. PASS
- SQLite Compatibility ..... PASS
- Architecture Compliance .. PASS

**Ready For Drift Generation — Phase 10 ✅**
