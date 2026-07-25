# SQLite Schema Extraction
## Phase 7 — Treasury & Cash Management
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`
**Date:** 2026-07-18

---

## Architecture Compliance & Single Source of Truth Mandate

> [!IMPORTANT]
> **Single Source of Truth Mandate for Treasury & Cash Management:**
> تطبيق **Flutter SQLite ERP** هو المصدر الرسمي والوحيد (Single Source of Truth) لجميع عمليات الخزينة وإدارة النقد والبنوك، وتشمل:
> (إدارة الصناديق النقدية، إدارة الحسابات البنكية، تسجيل المقبوضات، تسجيل المدفوعات، تخصيص المدفوعات، الحركات النقدية، الحركات البنكية، التسويات البنكية، وإدارة طرق الدفع). جميع هذه العمليات تتم محلياً داخل SQLite.
> 
> **مسؤولية Laravel PostgreSQL:**  
> ليس مسؤولاً عن تنفيذ أو تعديل عمليات الخزينة أو إنشاء الحركات النقدية والبنكية، وتقتصر مسؤوليته فقط على: استقبال البيانات بعد المزامنة، التقارير المركزية، لوحة التحكم Dashboard، التحليلات، وحفظ النسخة السحابية.
>
> **اتجاه المزامنة الرسمي:**  
> `Flutter SQLite ERP` → `Sync Engine` → `Laravel PostgreSQL` → `Dashboard / Reporting`
> 
> عند ظهور جداول سبق استخراجها أو جداول خارجية في العلاقات (`businesses`, `branches`, `users`, `customers`, `suppliers`, `chart_of_accounts`, `journal_entries`, `journal_entry_lines`, `customer_receivables`, `supplier_payables`, `currencies`, `fiscal_years`, `accounting_periods` إلخ)، يتم توثيق العلاقة فقط كمرجع دون إعادة استخراجها أو نسخ أعمدتها.

---

## 1. Table: `payment_methods`

### 1. General Information
- **Table Name:** `payment_methods`
- **Purpose:** Payment method definitions linked to a chart of account.
- **Domain:** DOMAIN 4 — FINANCE (Structure & Cash/Bank)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `chart_of_account_id`| `uuid` | No | — | Composite FK |
| `method_code` | `string(30)` | No | — | |
| `method_name` | `string(100)` | No | — | |
| `payment_type` | `string(20)` | No | — | CHECK: Cash, Bank, Card, DigitalWallet, Other |
| `is_active` | `boolean` | No | `true` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), composite `(business_id, chart_of_account_id)` → `chart_of_accounts` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, method_code)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `payment_methods` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `chart_of_accounts`| `payment_methods` | `belongsTo` | `chart_of_account_id`| `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `Payment` and `Expense`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, method_code)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `chart_of_account_id`, `method_code`, `method_name`, `payment_type`, `is_active`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, method_code)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `is_active` = `true`
- **CHECK Constraints:** `chk_pm_type` (`payment_type IN ('Cash', 'Bank', 'Card', 'DigitalWallet', 'Other')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(30)` / `(100)` / `(20)` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** طرق وأدوات الدفع تُعرّف محلياً داخل نظام الـ ERP وتستخدم عبر كافة نقاط البيع والصناديق لتوجيه المقبوضات والمدفوعات نحو حساباتها المحاسبية، وتتطلب المزامنة مع السحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 2. Table: `cash_registers`

### 1. General Information
- **Table Name:** `cash_registers`
- **Purpose:** Physical or logical cash registers per branch for POS operations.
- **Domain:** DOMAIN 4 — FINANCE (Structure & Cash/Bank)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `branch_id` | `uuid` | No | — | Composite FK |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `register_name` | `string(100)` | No | — | |
| `status` | `string(20)` | No | `'Closed'` | CHECK: Open, Closed |
| `current_balance` | `decimal(15,4)` | No | `0` | |
| `created_by` | `uuid` | Yes | — | FK → users (SET NULL) |
| `updated_by` | `uuid` | Yes | — | FK → users (SET NULL) |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), `currency_id` → `currencies.id` (RESTRICT), composite `(business_id, branch_id)` → `branches` (RESTRICT), `created_by` → `users.id` (SET NULL), `updated_by` → `users.id` (SET NULL)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, register_name)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `cash_registers` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `branches` | `cash_registers` | `belongsTo` | `branch_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `cash_registers` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `cash_registers` | `belongsTo` | `created_by` / `updated_by` | `SET NULL` | *غير محدد* |

*(Note: acts as parent `hasMany` for `CashTransaction`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, register_name)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `branch_id`, `currency_id`, `register_name`, `status`, `current_balance`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, register_name)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `status` = `'Closed'`, `current_balance` = `0`
- **CHECK Constraints:** `chk_cr_status` (`status IN ('Open', 'Closed')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` / `(20)` | `TEXT` | `TextColumn` |
| `decimal(15,4)` | `REAL` | `RealColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** فتح وإغلاق الصناديق النقدية وإدارة أرصدتها الحالية هو عصب عمليات نقاط البيع المحلية، ويجب رفع هذه الحالة والأرصدة إلى السحابة لضمان الرقابة المركزية.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 3. Table: `cash_transactions`

### 1. General Information
- **Table Name:** `cash_transactions`
- **Purpose:** Individual cash movement records within a register.
- **Domain:** DOMAIN 4 — FINANCE (Structure & Cash/Bank)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `cash_register_id` | `uuid` | No | — | FK → cash_registers (CASCADE) |
| `transaction_type` | `string(30)` | No | — | CHECK: Deposit, Withdrawal, Transfer In/Out, Adjustment, Payment, Receipt |
| `amount` | `decimal(15,4)` | No | — | CHECK: > 0 |
| `document_type` | `string(100)` | Yes | — | Polymorphic |
| `document_id` | `uuid` | Yes | — | Polymorphic |
| `notes` | `text` | Yes | — | |
| `reference_id` | `uuid` | Yes | — | Self-referential FK (SET NULL) |
| `created_by` | `uuid` | Yes | — | FK → users (SET NULL) |
| `created_at` | `timestamp` | No | `CURRENT_TIMESTAMP` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), `cash_register_id` → `cash_registers.id` (CASCADE), `reference_id` → `cash_transactions.id` (self, SET NULL), `created_by` → `users.id` (SET NULL)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `cash_transactions`| `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `cash_registers` | `cash_transactions`| `belongsTo` | `cash_register_id` | `CASCADE` | *غير محدد* |
| `cash_transactions`| `cash_transactions`| `belongsTo` (Self) | `reference_id` | `SET NULL` | *غير محدد* |
| `users` | `cash_transactions`| `belongsTo` | `created_by` | `SET NULL` | *غير محدد* |

*(Note: morphTo `financialDocument` via `document_type`, `document_id`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `cash_register_id`, `transaction_type`, `amount`, `created_at`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `created_at` = `CURRENT_TIMESTAMP`
- **CHECK Constraints:** `chk_ct_type` (`transaction_type IN ('Deposit', 'Withdrawal', 'Transfer In/Out', 'Adjustment', 'Payment', 'Receipt')`), `chk_ct_amount` (`amount > 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(30)` / `(100)` | `TEXT` | `TextColumn` |
| `decimal(15,4)` | `REAL` | `RealColumn` |
| `text` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** حركات الإيداع والسحب وتغذية الصناديق النقدية تحدث بشكل مستمر محلياً داخل الصندوق، وتتطلب الرفع الدوري للمزامنة وحفظ الحركة سحابياً.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 4. Table: `bank_accounts`

### 1. General Information
- **Table Name:** `bank_accounts`
- **Purpose:** Business bank accounts with balances and reconciliation tracking.
- **Domain:** DOMAIN 4 — FINANCE (Structure & Cash/Bank)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `branch_id` | `uuid` | Yes | — | Composite FK |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `account_number` | `string(50)` | No | — | |
| `iban` | `string(50)` | Yes | — | |
| `bank_name` | `string(100)` | No | — | |
| `display_name` | `string(100)` | Yes | — | |
| `description` | `text` | Yes | — | |
| `status` | `string(20)` | No | `'Active'` | CHECK: Active, Frozen, Closed |
| `is_default` | `boolean` | No | `false` | |
| `opening_balance` | `decimal(18,4)` | No | `0.0000` | |
| `opening_balance_date`| `date` | Yes | — | |
| `current_balance` | `decimal(18,4)` | No | `0.0000` | |
| `last_reconciled_balance`| `decimal(18,4)`| Yes| — | |
| `last_reconciled_at`| `timestamp` | Yes | — | |
| `created_by` | `uuid` | Yes | — | FK → users (NULL) |
| `updated_by` | `uuid` | Yes | — | FK → users (NULL) |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), `currency_id` → `currencies.id` (RESTRICT), composite `(business_id, branch_id)` → `branches` (RESTRICT), `created_by` → `users.id` (SET NULL), `updated_by` → `users.id` (SET NULL)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, account_number)`, `(business_id, iban)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `bank_accounts` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `branches` | `bank_accounts` | `belongsTo` | `branch_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `bank_accounts` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `bank_accounts` | `belongsTo` | `created_by` / `updated_by` | `SET NULL` | *غير محدد* |

*(Note: acts as parent `hasMany` for `BankTransaction`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, account_number)`, `(business_id, iban)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `currency_id`, `account_number`, `bank_name`, `status`, `is_default`, `opening_balance`, `current_balance`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, account_number)`, `(business_id, iban)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `status` = `'Active'`, `is_default` = `false`, `opening_balance` = `0.0000`, `current_balance` = `0.0000`
- **CHECK Constraints:** `chk_ba_status` (`status IN ('Active', 'Frozen', 'Closed')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(100)` / `(20)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `decimal(18,4)` | `REAL` | `RealColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** الحسابات البنكية وأرصدتها الحالية تُدار وتُحدّث محلياً بناءً على سندات المقبوضات والمدفوعات البنكية، وتتطلب الرفع والمزامنة مع الخادم.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 5. Table: `bank_transactions`

### 1. General Information
- **Table Name:** `bank_transactions`
- **Purpose:** Individual bank transaction records with multi-currency support.
- **Domain:** DOMAIN 4 — FINANCE (Structure & Cash/Bank)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `bank_account_id` | `uuid` | No | — | Composite FK |
| `transaction_type`| `string(50)` | No | — | CHECK: Deposit, Withdrawal, Transfer In/Out, Adjustment, Bank Fee, Interest, Opening Balance |
| `direction` | `string(10)` | No | — | CHECK: Credit, Debit |
| `amount` | `decimal(18,4)` | No | — | CHECK: > 0 |
| `foreign_currency_amount`| `decimal(18,4)`| Yes| — | |
| `foreign_currency_code`| `string(3)` | Yes | — | |
| `exchange_rate` | `decimal(18,6)` | Yes | — | |
| `document_type` | `string` | Yes | — | Polymorphic |
| `document_id` | `uuid` | Yes | — | Polymorphic |
| `bank_transfer_id`| `uuid` | Yes | — | |
| `reconciliation_status`| `string(30)` | No | `'Unreconciled'` | |
| `notes` | `text` | Yes | — | |
| `created_by` | `uuid` | Yes | — | FK → users (NULL) |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), composite `(business_id, bank_account_id)` → `bank_accounts` (CASCADE), `created_by` → `users.id` (SET NULL)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `bank_transactions`| `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `bank_accounts` | `bank_transactions`| `belongsTo` | `bank_account_id` | `CASCADE` | *غير محدد* |
| `users` | `bank_transactions`| `belongsTo` | `created_by` | `SET NULL` | *غير محدد* |

*(Note: morphTo `financialDocument` via `document_type`, `document_id`).*

### 5. Indexes
- **Indexes:** `(document_type, document_id)`
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `bank_account_id`, `transaction_type`, `direction`, `amount`, `reconciliation_status`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `reconciliation_status` = `'Unreconciled'`
- **CHECK Constraints:** `chk_bt_type` (`transaction_type IN ('Deposit', 'Withdrawal', 'Transfer In/Out', 'Adjustment', 'Bank Fee', 'Interest', 'Opening Balance')`), `chk_bt_direction` (`direction IN ('Credit', 'Debit')`), `chk_bt_amount` (`amount > 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(10)` / `(3)` / `(30)` | `TEXT` | `TextColumn` |
| `string` / `text` | `TEXT` | `TextColumn` |
| `decimal(18,4)` / `(18,6)` | `REAL` | `RealColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** الحركات والتحويلات والإيداعات والعمولات البنكية تُسجل محلياً في الـ ERP كجزء من إدارة الخزينة وتتطلب الرفع للمزامنة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 6. Table: `payments`

### 1. General Information
- **Table Name:** `payments`
- **Purpose:** Payment/receipt records with polymorphic contact linkage and multi-currency support.
- **Domain:** DOMAIN 7 — FINANCE (Payments & Receipts)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `branch_id` | `uuid` | No | — | Composite FK |
| `payment_number` | `string(50)` | No | — | |
| `payment_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `payment_method_id`| `uuid` | No | — | Composite FK |
| `chart_of_account_id`| `uuid` | No | — | Composite FK |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `exchange_rate` | `decimal(18,8)` | No | `1.00000000` | |
| `amount` | `decimal(18,2)` | No | — | |
| `base_amount` | `decimal(18,2)` | No | — | |
| `payment_type` | `string(20)` | No | — | CHECK: Receipt, Payment, Refund, Adjustment, Transfer |
| `contact_type` | `string(20)` | Yes | — | CHECK: Customer, Supplier, Employee, Other |
| `contact_id` | `uuid` | Yes | — | Polymorphic |
| `status` | `string(20)` | No | `'Draft'` | CHECK: Draft, Posted, Reversed |
| `notes` | `text` | Yes | — | |
| `created_by` | `uuid` | No | — | FK → users |
| `posted_by` | `uuid` | Yes | — | FK → users |
| `posted_at` | `timestamp` | Yes | — | |
| `reversed_by` | `uuid` | Yes | — | FK → users |
| `reversed_at` | `timestamp` | Yes | — | |
| `reversal_reason` | `text` | Yes | — | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |
| `deleted_at` | `timestamp` | Yes | — | Soft Delete |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `created_by` → `users.id` (RESTRICT), `posted_by` → `users.id` (RESTRICT), `reversed_by` → `users.id` (RESTRICT), composite `(business_id, branch_id)` → `branches`, composite `(business_id, payment_method_id)` → `payment_methods`, composite `(business_id, chart_of_account_id)` → `chart_of_accounts`
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, payment_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `payments` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `branches` | `payments` | `belongsTo` | `branch_id` | *غير محدد* | *غير محدد* |
| `payment_methods`| `payments` | `belongsTo` | `payment_method_id`| *غير محدد* | *غير محدد* |
| `chart_of_accounts`| `payments`| `belongsTo` | `chart_of_account_id`| *غير محدد* | *غير محدد* |
| `currencies` | `payments` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `payments` | `belongsTo` | `created_by` / `posted_by` / `reversed_by` | `RESTRICT` | *غير محدد* |

*(Note: morphTo `contact` via `contact_type`, `contact_id`; acts as parent `hasMany` for `PaymentAllocation`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, payment_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `branch_id`, `payment_number`, `payment_date`, `payment_method_id`, `chart_of_account_id`, `currency_id`, `exchange_rate`, `amount`, `base_amount`, `payment_type`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, payment_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `payment_date` = `CURRENT_TIMESTAMP`, `exchange_rate` = `1.00000000`, `status` = `'Draft'`
- **CHECK Constraints:** `chk_pay_type` (`payment_type IN ('Receipt', 'Payment', 'Refund', 'Adjustment', 'Transfer')`), `chk_pay_contact_type` (`contact_type IN ('Customer', 'Supplier', 'Employee', 'Other')`), `chk_pay_status` (`status IN ('Draft', 'Posted', 'Reversed')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(20)` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |
| `decimal(18,8)` / `(18,2)` | `REAL` | `RealColumn` |
| `text` | `TEXT` | `TextColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** سندات القبض والصرف واستلام الدفعات من العملاء والموردين تُصدر محلياً وتؤدي لتحديث الحسابات النقدية والذمم وتتطلب الرفع الفوري للمزامنة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 7. Table: `payment_allocations`

### 1. General Information
- **Table Name:** `payment_allocations`
- **Purpose:** Allocation of a payment to one or more documents (invoices, returns, etc.).
- **Domain:** DOMAIN 7 — FINANCE (Payments & Receipts)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `payment_id` | `uuid` | No | — | Composite FK |
| `amount` | `decimal(18,2)` | No | — | CHECK: > 0 |
| `document_type` | `string(50)` | No | — | Polymorphic |
| `document_id` | `uuid` | No | — | Polymorphic |
| `created_by` | `uuid` | No | — | FK → users |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), composite `(business_id, payment_id)` → `payments` (CASCADE), `created_by` → `users.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `payment_allocations`| `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `payments` | `payment_allocations`| `belongsTo` | `payment_id` | `CASCADE` | *غير محدد* |
| `users` | `payment_allocations`| `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

*(Note: morphTo `document` via `document_type`, `document_id`).*

### 5. Indexes
- **Indexes:** `idx_payment_allocations_doc` on `(document_type, document_id)`
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `payment_id`, `amount`, `document_type`, `document_id`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`
- **CHECK Constraints:** `chk_pa_amount` (`amount > 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `string(50)` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تخصيص المدفوعات لسداد الفواتير المفتوحة أو المرتجعات يتم محلياً ليغلق الذمة أو يخفض الرصيد المفتوح، ويتطلب المزامنة لتوثيق السداد في السحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 8. Table: `bank_reconciliations`

### 1. General Information
- **Table Name:** `bank_reconciliations`
- **Purpose:** Periodic statement reconciliations comparing bank statement balance against system ledger balance.
- **Domain:** DOMAIN 9 — SPECIALIZED MODULES & LEDGERS (Bank Reconciliations)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (RESTRICT) |
| `chart_of_account_id`| `uuid` | No | — | Composite FK → chart_of_accounts (RESTRICT) |
| `statement_date` | `date` | No | — | |
| `statement_balance` | `decimal(18,2)` | No | — | |
| `system_balance` | `decimal(18,2)` | No | — | |
| `difference` | `decimal(18,2)` | No | — | |
| `status` | `string(20)` | No | `'Draft'` | CHECK: Draft, Completed |
| `created_by` | `uuid` | No | — | FK → users (RESTRICT) |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), composite `(business_id, chart_of_account_id)` → `chart_of_accounts` (RESTRICT), `created_by` → `users.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `uq_bank_recon_date` on `(business_id, chart_of_account_id, statement_date)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `bank_reconciliations`| `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `chart_of_accounts`| `bank_reconciliations`| `belongsTo` | `chart_of_account_id`| `RESTRICT` | *غير محدد* |
| `users` | `bank_reconciliations`| `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `BankReconciliationLine`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `uq_bank_recon_date` on `(business_id, chart_of_account_id, statement_date)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `chart_of_account_id`, `statement_date`, `statement_balance`, `system_balance`, `difference`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `uq_bank_recon_date` on `(business_id, chart_of_account_id, statement_date)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `status` = `'Draft'`
- **CHECK Constraints:** `chk_br_status` (`status IN ('Draft', 'Completed')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `string(20)` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** التسويات البنكية الدورية ومقارنة كشوف الحساب بالدفاتر تُجرى محلياً وتحتاج للرفع والمزامنة لأرشفة حالة التسوية في السحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 9. Table: `bank_reconciliation_lines`

### 1. General Information
- **Table Name:** `bank_reconciliation_lines`
- **Purpose:** Individual transaction check lines cleared or uncleared during a bank reconciliation.
- **Domain:** DOMAIN 9 — SPECIALIZED MODULES & LEDGERS (Bank Reconciliations)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `bank_reconciliation_id`| `uuid`| No | — | Composite FK |
| `payment_id` | `uuid` | No | — | Composite FK → payments (RESTRICT) |
| `is_cleared` | `boolean` | No | `false` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** composite `(business_id, bank_reconciliation_id)` → `bank_reconciliations` (CASCADE), composite `(business_id, payment_id)` → `payments` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** None

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `bank_reconciliations`| `bank_reconciliation_lines`| `belongsTo` | `bank_reconciliation_id`| `CASCADE` | *غير محدد* |
| `payments` | `bank_reconciliation_lines`| `belongsTo` | `payment_id` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Indexes:** None

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `bank_reconciliation_id`, `payment_id`, `is_cleared`
- **UNIQUE Constraints:** None
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `is_cleared` = `false`
- **CHECK Constraints:** None
- **Database Triggers & Stored Validation Rules:**  
  يوجد قيد/تريجر على مستوى PostgreSQL باسم `trg_bank_recon_match` (`fn_bank_recon_match`) يتحقق من أن الدفعة (`payment_id`) التي يتم تصفيها/مطابقتها تنتمي إلى نفس الحساب البنكي (`chart_of_account_id`) والعملة (`currency_id`) المحددين في رأس التسوية البنكية.  
  *(تنبيه هندسي: سيتم نقل هذا المنطق والتحقق إلى طبقة الـ Domain / Repositories في تطبيق Flutter SQLite عند كتابة كود الخدمات، ولا يُنفذ على مستوى محرك SQLite).*

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** بنود السندات التي تم تعليمها كمطابقة/مصفاة خلال التسوية البنكية تُحفظ محلياً وتتطلب المزامنة مع الخادم.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## Final Verification Report

- Treasury Tables .......... PASS
- Columns Extraction ....... PASS
- Relationships ............ PASS
- Constraints .............. PASS
- Type Mapping ............. PASS
- SQLite Compatibility ..... PASS
- Architecture Compliance .. PASS

**Ready For Drift Generation — Phase 7 ✅**
