# SQLite Schema Extraction
## Phase 6 — Accounting Foundation (General Ledger)
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`
**Date:** 2026-07-18

---

## Architecture Compliance & Single Source of Truth Mandate

> [!IMPORTANT]
> **Single Source of Truth Mandate for Accounting Foundation:**
> تطبيق **Flutter SQLite ERP** هو المصدر الرسمي والوحيد (Single Source of Truth) لجميع البيانات المحاسبية التشغيلية، وتشمل:
> (إنشاء القيود اليومية، ترحيل القيود، دفتر الأستاذ العام General Ledger، شجرة الحسابات Chart of Accounts، الفترات المحاسبية، السنوات المالية، الأرصدة الافتتاحية، وربط الحسابات بالنظام Account Mappings). جميع هذه العمليات تتم محلياً داخل SQLite.
> 
> **مسؤولية Laravel PostgreSQL:**  
> ليس مسؤولاً عن تنفيذ أو تعديل العمليات المحاسبية أو القيود اليومية، وتقتصر مسؤوليته فقط على: استقبال البيانات بعد المزامنة، التقارير المركزية، التحليلات، لوحة التحكم Dashboard، وحفظ النسخة السحابية.
>
> **اتجاه المزامنة الرسمي:**  
> `Flutter SQLite ERP` → `Sync Engine` → `Laravel PostgreSQL` → `Dashboard / Reporting`
> 
> عند ظهور جداول سبق استخراجها أو جداول خارجية في العلاقات (`businesses`, `branches`, `users`, `customers`, `suppliers`, `products`, `product_units`, `currencies`, `payments`, `payment_allocations`, `customer_receivables`, `supplier_payables`, `account_types` إلخ)، يتم توثيق العلاقة فقط كمرجع دون إعادة استخراجها أو نسخ أعمدتها.

---

## 1. Table: `fiscal_years`

### 1. General Information
- **Table Name:** `fiscal_years`
- **Purpose:** Accounting fiscal year definitions per business.
- **Domain:** DOMAIN 4 — FINANCE (Structure & Cash/Bank)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `fiscal_year_code`| `string(20)` | No | — | |
| `fiscal_year_name`| `string(100)` | No | — | |
| `description` | `text` | Yes | — | |
| `start_date` | `date` | No | — | |
| `end_date` | `date` | No | — | CHECK: > start_date |
| `status` | `string(20)` | No | `'Open'` | CHECK: Open, Closed |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, fiscal_year_code)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `fiscal_years` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `FiscalPeriod`, `JournalEntry`, and `OpeningBalance`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, fiscal_year_code)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `fiscal_year_code`, `fiscal_year_name`, `start_date`, `end_date`, `status`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, fiscal_year_code)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `status` = `'Open'`
- **CHECK Constraints:** `chk_fy_status` (`status IN ('Open', 'Closed')`), `chk_fy_dates` (`end_date > start_date`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(20)` / `(100)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** فتح وإغلاق وتعريف السنوات المالية خاضع لإدارة الـ ERP المحلية (Source of Truth)، ويجب مزامنة حالتها والفترات التابعة لها مع الخادم.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 2. Table: `fiscal_periods`

### 1. General Information
- **Table Name:** `fiscal_periods`
- **Purpose:** Monthly periods within a fiscal year (1–12).
- **Domain:** DOMAIN 4 — FINANCE (Structure & Cash/Bank)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `fiscal_year_id` | `uuid` | No | — | Composite FK |
| `period_number` | `integer` | No | — | CHECK: 1–12 |
| `period_name` | `string(100)` | No | — | |
| `start_date` | `date` | No | — | |
| `end_date` | `date` | No | — | CHECK: > start_date |
| `status` | `string(20)` | No | `'Open'` | CHECK: Open, Closed |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** composite `(business_id, fiscal_year_id)` → `fiscal_years` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(fiscal_year_id, period_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `fiscal_periods` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `fiscal_years` | `fiscal_periods` | `belongsTo` | `fiscal_year_id` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `JournalEntry`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(fiscal_year_id, period_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `fiscal_year_id`, `period_number`, `period_name`, `start_date`, `end_date`, `status`
- **UNIQUE Constraints:** `(business_id, id)`, `(fiscal_year_id, period_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `status` = `'Open'`
- **CHECK Constraints:** `chk_fp_status` (`status IN ('Open', 'Closed')`), `chk_fp_period` (`period_number BETWEEN 1 AND 12`), `chk_fp_dates` (`end_date > start_date`)
- **Triggers Note:** Has DB trigger `trg_fiscal_period_overlap` in PostgreSQL to prevent overlapping date intervals within the same fiscal year.

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `integer` | `INTEGER` | `IntColumn` |
| `string(100)` / `(20)` | `TEXT` | `TextColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** الفترات المالية وحالة إغلاقها أو فتحها تؤثر مباشرة على صلاحية تسجيل القيود اليومية محلياً، وتتطلب الرفع والمزامنة مع السحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 3. Table: `accounting_periods`

### 1. General Information
- **Table Name:** `accounting_periods`
- **Purpose:** Financial accounting period close status management preventing modification of closed period data.
- **Domain:** DOMAIN 9 — SPECIALIZED MODULES & LEDGERS (Financial Closing)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (RESTRICT) |
| `fiscal_year_id` | `uuid` | No | — | Composite FK → fiscal_years (RESTRICT) |
| `period_number` | `integer` | No | — | |
| `period_name` | `string(50)` | No | — | e.g. January 2026 |
| `start_date` | `date` | No | — | |
| `end_date` | `date` | No | — | |
| `status` | `string(20)` | No | `'Open'` | CHECK: Open, Closed, Locked |
| `closed_by` | `uuid` | Yes | — | FK → users (SET NULL) |
| `closed_at` | `timestamp` | Yes | — | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), composite `(business_id, fiscal_year_id)` → `fiscal_years` (RESTRICT), `closed_by` → `users.id` (SET NULL)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, fiscal_year_id, period_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `accounting_periods` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `fiscal_years` | `accounting_periods` | `belongsTo` | `fiscal_year_id` | `RESTRICT` | *غير محدد* |
| `users` | `accounting_periods` | `belongsTo` | `closed_by` | `SET NULL` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, fiscal_year_id, period_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `fiscal_year_id`, `period_number`, `period_name`, `start_date`, `end_date`, `status`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, fiscal_year_id, period_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `status` = `'Open'`
- **CHECK Constraints:** `chk_ap_status` (`status IN ('Open', 'Closed', 'Locked')`), `chk_ap_dates` (`end_date >= start_date`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `integer` | `INTEGER` | `IntColumn` |
| `string(50)` / `(20)` | `TEXT` | `TextColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** قفل وإغلاق الفترات المحاسبية يمنع ترحيل القيود وتعديل الحركات محلياً في SQLite، ويجب التزامن الفوري مع السحابة والأجهزة الأخرى لضمان عدم حدوث تعارض مالي.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 4. Table: `chart_of_accounts`

### 1. General Information
- **Table Name:** `chart_of_accounts`
- **Purpose:** Full chart of accounts with hierarchical parent-child structure. Core of the accounting system.
- **Domain:** DOMAIN 4 — FINANCE (Structure & Cash/Bank)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `parent_account_id` | `uuid` | Yes | — | Self-referential composite FK |
| `currency_id` | `uuid` | Yes | — | FK → currencies |
| `account_code` | `string(50)` | No | — | |
| `account_name` | `string(255)` | No | — | |
| `description` | `text` | Yes | — | |
| `account_type_id` | `bigint` | No | — | FK → account_types |
| `account_category`| `string(100)` | Yes | — | |
| `normal_balance` | `string(10)` | No | — | CHECK: Debit, Credit |
| `account_level` | `integer` | No | `1` | CHECK: > 0 |
| `allow_posting` | `boolean` | No | `false` | |
| `is_system` | `boolean` | No | `false` | |
| `is_active` | `boolean` | No | `true` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `account_type_id` → `account_types.id` (RESTRICT), composite `(business_id, parent_account_id)` → `chart_of_accounts` (self, RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, account_code)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `chart_of_accounts` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `chart_of_accounts`| `chart_of_accounts` | `belongsTo` (Parent/Child) | `parent_account_id`| `RESTRICT` | *غير محدد* |
| `currencies` | `chart_of_accounts` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `account_types` | `chart_of_accounts` | `belongsTo` | `account_type_id` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `JournalEntryLine`, `OpeningBalance`, `AccountMapping`, `Customer.receivableAccount`, `Supplier.payableAccount`, `PaymentMethod`, `Payment`, `BankReconciliation` etc.).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, account_code)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `account_code`, `account_name`, `account_type_id`, `normal_balance`, `account_level`, `allow_posting`, `is_system`, `is_active`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, account_code)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `account_level` = `1`, `allow_posting` = `false`, `is_system` = `false`, `is_active` = `true`
- **CHECK Constraints:** `chk_coa_balance` (`normal_balance IN ('Debit', 'Credit')`), `chk_coa_level` (`account_level > 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(255)` / `(100)` / `(10)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `bigint` | `INTEGER` | `IntColumn` (or Int64) |
| `integer` | `INTEGER` | `IntColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** شجرة الحسابات هي العمود الفقري لجميع العمليات المالية والحركات داخل الفروع، وتدار محلياً في الـ ERP وتخضع للمزامنة لتوحيد شجرة الحسابات السحابية والمحاسبية.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 5. Table: `journal_entries`

### 1. General Information
- **Table Name:** `journal_entries`
- **Purpose:** General ledger journal entry headers. All financial postings flow through this table.
- **Domain:** DOMAIN 7 — FINANCE (Journals & General Ledger)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `fiscal_year_id` | `uuid` | No | — | Composite FK |
| `fiscal_period_id`| `uuid` | No | — | |
| `journal_number` | `string(50)` | No | — | |
| `document_date` | `date` | No | — | |
| `posting_date` | `date` | Yes | — | |
| `journal_type` | `string(50)` | No | — | CHECK: Manual, SalesInvoice, PurchaseInvoice, Payment, InventoryAdjustment, Reverse |
| `document_type` | `string(50)` | No | — | CHECK: same as journal_type |
| `document_id` | `uuid` | Yes | — | Polymorphic reference |
| `document_number` | `string(50)` | Yes | — | |
| `original_journal_id`| `uuid`| Yes | — | Self-referential FK |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `exchange_rate` | `decimal(18,8)` | No | `1.00000000` | |
| `description` | `text` | Yes | — | |
| `status` | `string(20)` | No | `'Draft'` | CHECK: Draft, Posted, Reversed |
| `created_by` | `uuid` | No | — | FK → users |
| `posted_by` | `uuid` | Yes | — | FK → users |
| `reversed_by` | `uuid` | Yes | — | FK → users |
| `posted_at` | `timestamp` | Yes | — | |
| `reversed_at` | `timestamp` | Yes | — | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `created_by` → `users.id` (RESTRICT), `posted_by` → `users.id` (RESTRICT), `reversed_by` → `users.id` (RESTRICT), `original_journal_id` → `journal_entries.id` (self, RESTRICT), composite `(business_id, fiscal_year_id)` → `fiscal_years`, `fiscal_period_id` → `fiscal_periods.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, journal_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `journal_entries` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `fiscal_years` | `journal_entries` | `belongsTo` | `fiscal_year_id` | *غير محدد* | *غير محدد* |
| `fiscal_periods` | `journal_entries` | `belongsTo` | `fiscal_period_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `journal_entries` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `journal_entries` | `belongsTo` | `created_by` / `posted_by` / `reversed_by` | `RESTRICT` | *غير محدد* |
| `journal_entries`| `journal_entries` | `belongsTo` (Self) | `original_journal_id`| `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `JournalEntryLine` and polymorphic relation to source financial documents).*

### 5. Indexes
- **Indexes:** `idx_je_document` on `(document_type, document_id)`
- **Unique Indexes:** `(business_id, id)`, `(business_id, journal_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `fiscal_year_id`, `fiscal_period_id`, `journal_number`, `document_date`, `journal_type`, `document_type`, `currency_id`, `exchange_rate`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, journal_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `exchange_rate` = `1.00000000`, `status` = `'Draft'`
- **CHECK Constraints:** `chk_je_jnl_type`, `chk_je_doc_type`, `chk_je_status` (`status IN ('Draft', 'Posted', 'Reversed')`)
- **Triggers Note:** Has DB trigger `trg_journal_balance_check` in PostgreSQL that prevents posting unless base debits = base credits. (In SQLite, must be enforced in Domain layer/Repositories).

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(20)` | `TEXT` | `TextColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `decimal(18,8)` | `REAL` | `RealColumn` |
| `text` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** جميع القيود اليومية التشغيلية (اليدوية وتلك الناتجة تلقائياً عن الفواتير والمرتجعات والسندات) تُنشأ وتُعتمد في SQLite وتتطلب الرفع للمزامنة الدقيقة لدفتر الأستاذ العام في السحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 6. Table: `journal_entry_lines`

### 1. General Information
- **Table Name:** `journal_entry_lines`
- **Purpose:** Individual debit/credit lines within a journal entry.
- **Domain:** DOMAIN 7 — FINANCE (Journals & General Ledger)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `journal_entry_id`| `uuid` | No | — | Composite FK |
| `line_number` | `integer` | No | — | |
| `chart_of_account_id`| `uuid` | No | — | Composite FK |
| `description` | `text` | Yes | — | |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `exchange_rate` | `decimal(18,8)` | No | `1.00000000` | |
| `type` | `string(10)` | No | — | CHECK: Debit, Credit |
| `foreign_amount`| `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `base_amount` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `document_type` | `string(50)` | Yes | — | Polymorphic |
| `document_id` | `uuid` | Yes | — | Polymorphic |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** composite `(business_id, journal_entry_id)` → `journal_entries` (CASCADE), composite `(business_id, chart_of_account_id)` → `chart_of_accounts` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(journal_entry_id, line_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `journal_entries` | `journal_entry_lines`| `belongsTo` | `journal_entry_id` | `CASCADE` | *غير محدد* |
| `chart_of_accounts`| `journal_entry_lines`| `belongsTo` | `chart_of_account_id`| `RESTRICT` | *غير محدد* |
| `currencies` | `journal_entry_lines`| `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |

*(Note: morphTo `financialDocument` via `document_type`, `document_id`).*

### 5. Indexes
- **Unique Indexes:** `(journal_entry_id, line_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `journal_entry_id`, `line_number`, `chart_of_account_id`, `currency_id`, `exchange_rate`, `type`, `foreign_amount`, `base_amount`
- **UNIQUE Constraints:** `(journal_entry_id, line_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `exchange_rate` = `1.00000000`, `foreign_amount` = `0.00`, `base_amount` = `0.00`
- **CHECK Constraints:** `chk_jel_type` (`type IN ('Debit', 'Credit')`), `chk_jel_amount` (`foreign_amount >= 0, base_amount >= 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `integer` | `INTEGER` | `IntColumn` |
| `text` | `TEXT` | `TextColumn` |
| `decimal(18,8)` / `(18,2)` | `REAL` | `RealColumn` |
| `string(10)` / `(50)` | `TEXT` | `TextColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تابعة بشكل مباشر لترويسة القيد اليومي وتُعد النواة الفعلية لتسجيل المدين والدائن محلياً في شجرة الحسابات وتتطلب الرفع للمزامنة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 7. Table: `opening_balances`

### 1. General Information
- **Table Name:** `opening_balances`
- **Purpose:** Opening balance entries per fiscal year per chart of account, with multi-currency support.
- **Domain:** DOMAIN 7 — FINANCE (Journals & General Ledger)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `fiscal_year_id` | `uuid` | No | — | Composite FK |
| `chart_of_account_id`| `uuid` | No | — | Composite FK |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `exchange_rate` | `decimal(18,8)` | No | `1.00000000` | |
| `debit_amount` | `decimal(18,2)` | No | `0.00` | |
| `credit_amount` | `decimal(18,2)` | No | `0.00` | |
| `base_debit_amount`| `decimal(18,2)` | No | `0.00` | |
| `base_credit_amount`| `decimal(18,2)`| No | `0.00` | |
| `created_by` | `uuid` | No | — | FK → users |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `created_by` → `users.id` (RESTRICT), composite `(business_id, fiscal_year_id)` → `fiscal_years`, composite `(business_id, chart_of_account_id)` → `chart_of_accounts`
- **Composite Keys:** None
- **Unique Constraints:** `(fiscal_year_id, chart_of_account_id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `opening_balances`| `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `fiscal_years` | `opening_balances`| `belongsTo` | `fiscal_year_id` | *غير محدد* | *غير محدد* |
| `chart_of_accounts`| `opening_balances`| `belongsTo` | `chart_of_account_id`| *غير محدد* | *غير محدد* |
| `currencies` | `opening_balances`| `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `opening_balances`| `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(fiscal_year_id, chart_of_account_id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `fiscal_year_id`, `chart_of_account_id`, `currency_id`, `exchange_rate`, `debit_amount`, `credit_amount`, `base_debit_amount`, `base_credit_amount`, `created_by`
- **UNIQUE Constraints:** `(fiscal_year_id, chart_of_account_id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `exchange_rate` = `1.00000000`, `debit_amount` = `0.00`, `credit_amount` = `0.00`, `base_debit_amount` = `0.00`, `base_credit_amount` = `0.00`
- **CHECK Constraints:** `chk_ob_xor` (either debit or credit, not both), `chk_ob_base_xor`
- **Triggers Note:** Has DB trigger `trg_opening_bal_match` in PostgreSQL to validate fiscal year and COA belong to same business.

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,8)` / `(18,2)` | `REAL` | `RealColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** إدخال وتعديل الأرصدة الافتتاحية للحسابات والسنوات المالية يُسجل محلياً في SQLite كبداية للانطلاق المحاسبي ويجب مزامنته وحفظ الرقم التسلسلي والحالة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 8. Table: `account_mappings`

### 1. General Information
- **Table Name:** `account_mappings`
- **Purpose:** System default posting rules mapping transaction events to chart of accounts (e.g. Sales Tax Payable, Inventory Control).
- **Domain:** DOMAIN 9 — SPECIALIZED MODULES & LEDGERS (Account Mappings)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `mapping_key` | `string(100)` | No | — | e.g., default_sales_tax, inventory_asset |
| `mapping_name` | `string(150)` | No | — | Human-readable description |
| `chart_of_account_id`| `uuid` | No | — | Composite FK → chart_of_accounts (RESTRICT) |
| `is_active` | `boolean` | No | `true` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), composite `(business_id, chart_of_account_id)` → `chart_of_accounts` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, mapping_key)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `account_mappings` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `chart_of_accounts`| `account_mappings` | `belongsTo` | `chart_of_account_id`| `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, mapping_key)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `mapping_key`, `mapping_name`, `chart_of_account_id`, `is_active`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, mapping_key)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `is_active` = `true`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` / `(150)` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** إعدادات ربط الحسابات (Account Mappings) هي المرجع الأساسي للتوجيه المحاسبي التلقائي للفواتير والحركات المحلية في SQLite، وتدار محلياً وتتطلب مزامنة إعداداتها بين الأجهزة والسحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## Final Verification Report

- Accounting Tables ........ PASS
- Columns Extraction ....... PASS
- Relationships ............ PASS
- Constraints .............. PASS
- Type Mapping ............. PASS
- SQLite Compatibility ..... PASS
- Architecture Compliance .. PASS

**Ready For Drift Generation — Phase 6 ✅**
