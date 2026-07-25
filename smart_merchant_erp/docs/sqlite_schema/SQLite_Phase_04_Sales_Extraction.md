# SQLite Schema Extraction
## Phase 4 — Sales & Customer Management
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`
**Date:** 2026-07-18

---

## Architecture Compliance & Single Source of Truth Mandate

> [!IMPORTANT]
> **Single Source of Truth Mandate for Sales & Customers:**
> تطبيق **Flutter SQLite ERP** هو المصدر الرسمي والوحيد (Single Source of Truth) لجميع العمليات التشغيلية اليومية الخاصة بالمبيعات والعملاء، وتشمل:
> (إنشاء وتعديل وأرشفة العملاء، إنشاء عروض الأسعار، إصدار فواتير البيع، مرتجعات البيع، إدارة الذمم المدينة، تسجيل مدفوعات العملاء، تحديث الأرصدة، وتشغيل نقاط البيع POS).
> 
> **مسؤولية Laravel PostgreSQL:**  
> ليس مسؤولاً عن تنفيذ أو إدارة عمليات البيع، وتقتصر مسؤوليته فقط على: استقبال البيانات بعد المزامنة، حفظ نسخة سحابية، التقارير المركزية والتحليلات، المزامنة بين الأجهزة، وخدمة لوحة التحكم والمتجر الإلكتروني عند الحاجة.
>
> **اتجاه المزامنة الرسمي:**  
> `Flutter SQLite ERP` → `Sync Engine` → `Laravel PostgreSQL` → `Dashboard / Reporting / E-Commerce`
> 
> عند ظهور جداول سبق استخراجها أو جداول خارجية في العلاقات (`businesses`, `branches`, `users`, `warehouses`, `inventories`, `products`, `product_units`, `taxes`, إلخ)، يتم توثيق العلاقة فقط كمرجع دون إعادة استخراجها أو نسخ أعمدتها.

---

## 1. Table: `customers`

### 1. General Information
- **Table Name:** `customers`
- **Purpose:** Customer master data with credit terms, opening balances, and linked accounting accounts.
- **Domain:** DOMAIN 5 — SALES & CUSTOMERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `customer_name` | `string(255)` | No | — | |
| `phone` | `string(30)` | Yes | — | |
| `email` | `string(255)` | Yes | — | |
| `address` | `text` | Yes | — | |
| `credit_limit` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `default_currency_id` | `uuid` | Yes | — | FK → currencies (NULL ON DELETE) |
| `payment_term_id` | `uuid` | Yes | — | Composite FK |
| `receivable_account_id` | `uuid` | Yes | — | Composite FK → chart_of_accounts |
| `opening_balance` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `opening_balance_type`| `string(10)` | Yes | — | CHECK: debit, credit |
| `opening_balance_date`| `date` | Yes | — | |
| `is_active` | `boolean` | No | `true` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |
| `deleted_at` | `timestamp` | Yes | — | Soft Delete |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `default_currency_id` → `currencies.id` (NULL), `(business_id, payment_term_id)` → `payment_terms` (RESTRICT), `(business_id, receivable_account_id)` → `chart_of_accounts` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `customers` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `customers` | `belongsTo` | `default_currency_id` | `SET NULL` | *غير محدد* |
| `payment_terms` | `customers` | `belongsTo` | `payment_term_id` | `RESTRICT` | *غير محدد* |
| `chart_of_accounts` | `customers` | `belongsTo` | `receivable_account_id`| `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `SalesInvoice`, `Order`, `Cart`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `customer_name`, `credit_limit`, `opening_balance`, `is_active`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `credit_limit` = `0.00`, `opening_balance` = `0.00`, `is_active` = `true`
- **CHECK Constraints:** `chk_cust_credit` (`credit_limit >= 0`), `chk_cust_balance` (`opening_balance >= 0`), `chk_cust_bal_type` (`opening_balance_type IN ('debit', 'credit')`), `chk_cust_bal_req`

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(255)` / `(30)` / `(10)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** بيانات العملاء تُنشأ وتُعدل محلياً داخل نظام الـ ERP في الفروع ونقاط البيع (Source of Truth)، وتحتاج لمزامنة دورية وسحابية لضمان تطابق الأرصدة والبيانات.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 2. Table: `sales_invoices`

### 1. General Information
- **Table Name:** `sales_invoices`
- **Purpose:** Sales invoice headers with multi-currency support and dual totals.
- **Domain:** DOMAIN 5 — SALES & CUSTOMERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `branch_id` | `uuid` | No | — | Composite FK |
| `customer_id` | `uuid` | Yes | — | Composite FK (null for walk-in) |
| `invoice_number` | `string(50)` | No | — | |
| `invoice_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `due_date` | `timestamp` | Yes | — | |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `exchange_rate` | `decimal(18,8)` | No | `1.00000000` | |
| `sub_total` | `decimal(18,2)` | No | `0.00` | |
| `discount_total` | `decimal(18,2)` | No | `0.00` | |
| `tax_total` | `decimal(18,2)` | No | `0.00` | |
| `grand_total` | `decimal(18,2)` | No | `0.00` | |
| `base_sub_total` | `decimal(18,2)` | No | `0.00` | |
| `base_discount_total` | `decimal(18,2)` | No | `0.00` | |
| `base_tax_total` | `decimal(18,2)` | No | `0.00` | |
| `base_grand_total` | `decimal(18,2)` | No | `0.00` | |
| `payment_status` | `string(20)` | No | `'Unpaid'` | CHECK: Unpaid, Partial, Paid |
| `status` | `string(20)` | No | `'Draft'` | CHECK: Draft, Posted, Reversed |
| `notes` | `text` | Yes | — | |
| `created_by` | `uuid` | No | — | FK → users |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `created_by` → `users.id` (RESTRICT), `(business_id, branch_id)` → `branches`, `(business_id, customer_id)` → `customers`
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, invoice_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `sales_invoices` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `branches` | `sales_invoices` | `belongsTo` | `branch_id` | *غير محدد* | *غير محدد* |
| `customers` | `sales_invoices` | `belongsTo` | `customer_id` | *غير محدد* | *غير محدد* |
| `currencies` | `sales_invoices` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `sales_invoices` | `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `SalesInvoiceItem` and `SalesReturn`).*

### 5. Indexes
- **Indexes:** `idx_sales_invoices_status` on `(status, payment_status)`
- **Unique Indexes:** `(business_id, id)`, `(business_id, invoice_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `branch_id`, `invoice_number`, `invoice_date`, `currency_id`, `exchange_rate`, `sub_total`, `discount_total`, `tax_total`, `grand_total`, `base_sub_total`, `base_discount_total`, `base_tax_total`, `base_grand_total`, `payment_status`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, invoice_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `invoice_date` = `CURRENT_TIMESTAMP`, `exchange_rate` = `1.00000000`, numeric totals = `0.00`, `payment_status` = `'Unpaid'`, `status` = `'Draft'`
- **CHECK Constraints:** `chk_si_payment` (`payment_status IN ('Unpaid', 'Partial', 'Paid')`), `chk_si_status` (`status IN ('Draft', 'Posted', 'Reversed')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(20)` | `TEXT` | `TextColumn` |
| `decimal(18,8)` / `(18,2)` | `REAL` | `RealColumn` |
| `text` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** الفواتير تُصدر يومياً من الأجهزة ونقاط البيع المحلية (Offline-First)، ويجب رفع الحركات وتتبع حالة المزامنة وحفظ الرقم التسلسلي والحالة السحابية.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 3. Table: `sales_invoice_items`

### 1. General Information
- **Table Name:** `sales_invoice_items`
- **Purpose:** Line items for sales invoices with cost tracking and optional order item linkage.
- **Domain:** DOMAIN 5 — SALES & CUSTOMERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `sales_invoice_id`| `uuid` | No | — | Composite FK |
| `order_item_id` | `uuid` | Yes | — | FK → order_items (NULL ON DELETE) |
| `product_unit_id` | `uuid` | No | — | Composite FK |
| `warehouse_id` | `uuid` | No | — | Composite FK |
| `tax_id` | `uuid` | Yes | — | No FK constraint (commented out in original) |
| `quantity` | `decimal(18,3)` | No | — | CHECK: > 0 |
| `unit_price` | `decimal(18,2)` | No | — | CHECK: >= 0 |
| `cost_price` | `decimal(18,2)` | No | `0.00` | |
| `discount` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `tax` | `decimal(18,2)` | No | `0.00` | |
| `line_total` | `decimal(18,2)` | No | — | |
| `cost_total` | `decimal(18,2)` | No | `0.00` | |
| `base_line_total` | `decimal(18,2)` | No | `0.00` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, sales_invoice_id)` → `sales_invoices` (CASCADE), `order_item_id` → `order_items.id` (NULL), `(business_id, product_unit_id)` → `product_units` (RESTRICT), `(business_id, warehouse_id)` → `warehouses` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `sales_invoices` | `sales_invoice_items`| `belongsTo` | `sales_invoice_id` | `CASCADE` | *غير محدد* |
| `order_items` | `sales_invoice_items`| `belongsTo` | `order_item_id` | `SET NULL` | *غير محدد* |
| `product_units` | `sales_invoice_items`| `belongsTo` | `product_unit_id` | `RESTRICT` | *غير محدد* |
| `warehouses` | `sales_invoice_items`| `belongsTo` | `warehouse_id` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `SalesReturnItem`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `sales_invoice_id`, `product_unit_id`, `warehouse_id`, `quantity`, `unit_price`, `cost_price`, `discount`, `tax`, `line_total`, `cost_total`, `base_line_total`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `cost_price` = `0.00`, `discount` = `0.00`, `tax` = `0.00`, `cost_total` = `0.00`, `base_line_total` = `0.00`
- **CHECK Constraints:** `chk_sii_quantity` (`quantity > 0`), `chk_sii_price` (`unit_price >= 0`), `chk_sii_discount` (`discount >= 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,3)` / `(18,2)` | `REAL` | `RealColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تابعة بشكل مباشر لرأس الفاتورة وتُنشأ وتُدار معها محلياً، وتحتاج لمزامنة تفاصيل البنود والكميات وحركات المخزون المقابلة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 4. Table: `sales_returns`

### 1. General Information
- **Table Name:** `sales_returns`
- **Purpose:** Sales return headers linked to a sales invoice.
- **Domain:** DOMAIN 5 — SALES & CUSTOMERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `branch_id` | `uuid` | No | — | Composite FK |
| `sales_invoice_id`| `uuid` | No | — | Composite FK |
| `return_number` | `string(50)` | No | — | |
| `return_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `exchange_rate` | `decimal(18,8)` | No | `1.00000000` | |
| `total_amount` | `decimal(18,2)` | No | `0.00` | |
| `base_total_amount`| `decimal(18,2)` | No | `0.00` | |
| `status` | `string(20)` | No | `'Draft'` | |
| `notes` | `text` | Yes | — | |
| `created_by` | `uuid` | No | — | FK → users |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |
| `deleted_at` | `timestamp` | Yes | — | Soft Delete |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `created_by` → `users.id` (RESTRICT), `(business_id, branch_id)` → `branches`, `(business_id, sales_invoice_id)` → `sales_invoices`
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, return_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `sales_returns` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `branches` | `sales_returns` | `belongsTo` | `branch_id` | *غير محدد* | *غير محدد* |
| `sales_invoices` | `sales_returns` | `belongsTo` | `sales_invoice_id` | *غير محدد* | *غير محدد* |
| `currencies` | `sales_returns` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `sales_returns` | `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `SalesReturnItem`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, return_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `branch_id`, `sales_invoice_id`, `return_number`, `return_date`, `currency_id`, `exchange_rate`, `total_amount`, `base_total_amount`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, return_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `return_date` = `CURRENT_TIMESTAMP`, `exchange_rate` = `1.00000000`, totals = `0.00`, `status` = `'Draft'`
- **CHECK Constraints:** None (Has DB trigger `trg_sales_return_qty` in PostgreSQL to validate return qty <= invoiced qty).

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(20)` | `TEXT` | `TextColumn` |
| `decimal(18,8)` / `(18,2)` | `REAL` | `RealColumn` |
| `text` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** عمليات مرتجعات البيع تُجرى محلياً على الفواتير المكتملة وتؤثر على المخزون والأرصدة، وتحتاج الرفع للسحابة عبر محرك المزامنة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 5. Table: `sales_return_items`

### 1. General Information
- **Table Name:** `sales_return_items`
- **Purpose:** Line items for sales returns, linked to original sales invoice items.
- **Domain:** DOMAIN 5 — SALES & CUSTOMERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `sales_return_id` | `uuid` | No | — | Composite FK |
| `sales_invoice_item_id`| `uuid` | No | — | FK → sales_invoice_items |
| `warehouse_id` | `uuid` | No | — | Composite FK |
| `quantity` | `decimal(18,3)` | No | — | |
| `unit_price` | `decimal(18,2)` | No | — | |
| `cost_price` | `decimal(18,2)` | No | `0.00` | |
| `total_price` | `decimal(18,2)` | No | — | |
| `cost_total` | `decimal(18,2)` | No | `0.00` | |
| `base_total_price`| `decimal(18,2)` | No | `0.00` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, sales_return_id)` → `sales_returns` (CASCADE), `sales_invoice_item_id` → `sales_invoice_items.id` (RESTRICT), `(business_id, warehouse_id)` → `warehouses` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `sales_returns` | `sales_return_items` | `belongsTo` | `sales_return_id` | `CASCADE` | *غير محدد* |
| `sales_invoice_items`| `sales_return_items` | `belongsTo` | `sales_invoice_item_id`| `RESTRICT` | *غير محدد* |
| `warehouses` | `sales_return_items` | `belongsTo` | `warehouse_id` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `sales_return_id`, `sales_invoice_item_id`, `warehouse_id`, `quantity`, `unit_price`, `cost_price`, `total_price`, `cost_total`, `base_total_price`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `cost_price` = `0.00`, `cost_total` = `0.00`, `base_total_price` = `0.00`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,3)` / `(18,2)` | `REAL` | `RealColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** بنود المرتجعات تابعة لرأس حركة المرتجع وتُسجل محلياً لضمان إعادة الكميات للمستودع وإعادة ضبط الحسابات.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 6. Table: `customer_receivables`

### 1. General Information
- **Table Name:** `customer_receivables`
- **Purpose:** Accounts Receivable (A/R) sub-ledger tracking open invoices, paid amounts, due dates, and aging per customer.
- **Domain:** DOMAIN 5 — SALES & CUSTOMERS (Accounts Receivable)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (RESTRICT) |
| `customer_id` | `uuid` | No | — | Composite FK → customers (RESTRICT) |
| `sales_invoice_id`| `uuid` | No | — | Composite FK → sales_invoices (RESTRICT) |
| `currency_id` | `uuid` | No | — | FK → currencies (RESTRICT) |
| `exchange_rate` | `decimal(18,8)` | No | `1.00000000` | |
| `original_amount` | `decimal(18,2)` | No | — | |
| `base_original_amount`| `decimal(18,2)`| No | — | |
| `paid_amount` | `decimal(18,2)` | No | `0.00` | |
| `base_paid_amount`| `decimal(18,2)` | No | `0.00` | |
| `remaining_amount`| `decimal(18,2)` | No | — | |
| `base_remaining_amount`| `decimal(18,2)`| No| — | |
| `due_date` | `date` | Yes | — | |
| `status` | `string(20)` | No | `'Unpaid'` | CHECK: Unpaid, Partial, Paid |
| `last_payment_date`| `date` | Yes | — | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `(business_id, customer_id)` → `customers` (RESTRICT), `(business_id, sales_invoice_id)` → `sales_invoices` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, sales_invoice_id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `customer_receivables` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `customers` | `customer_receivables` | `belongsTo` | `customer_id` | `RESTRICT` | *غير محدد* |
| `sales_invoices` | `customer_receivables` | `belongsTo` | `sales_invoice_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `customer_receivables` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `ReceivableEntry`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, sales_invoice_id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `customer_id`, `sales_invoice_id`, `currency_id`, `exchange_rate`, `original_amount`, `base_original_amount`, `paid_amount`, `base_paid_amount`, `remaining_amount`, `base_remaining_amount`, `status`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, sales_invoice_id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `exchange_rate` = `1.00000000`, `paid_amount` = `0.00`, `base_paid_amount` = `0.00`, `status` = `'Unpaid'`
- **CHECK Constraints:** `chk_cr_status` (`status IN ('Unpaid', 'Partial', 'Paid')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,8)` / `(18,2)` | `REAL` | `RealColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `string(20)` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** إدارة الذمم المدينة والتحصيلات هي جزء حاسم من المبيعات التشغيلية المحلية (Source of Truth)، وتحتاج لمزامنة أرصدة وحالات السداد مع السحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 7. Table: `receivable_entries`

### 1. General Information
- **Table Name:** `receivable_entries`
- **Purpose:** Detailed tracking history of payment allocations against accounts receivable records.
- **Domain:** DOMAIN 5 — SALES & CUSTOMERS (Accounts Receivable)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `customer_receivable_id`| `uuid` | No | — | Composite FK → customer_receivables (CASCADE) |
| `payment_id` | `uuid` | Yes | — | Composite FK → payments (SET NULL) |
| `payment_allocation_id` | `uuid` | Yes | — | Composite FK → payment_allocations (SET NULL) |
| `entry_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `amount` | `decimal(18,2)` | No | — | |
| `base_amount` | `decimal(18,2)` | No | — | |
| `entry_type` | `string(20)` | No | `'Payment'` | CHECK: Payment, Adjustment, WriteOff |
| `created_by` | `uuid` | No | — | FK → users (RESTRICT) |
| `created_at` | `timestamp` | No | `CURRENT_TIMESTAMP` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, customer_receivable_id)` → `customer_receivables` (CASCADE), `(business_id, payment_id)` → `payments` (SET NULL), `(business_id, payment_allocation_id)` → `payment_allocations` (SET NULL), `created_by` → `users.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `customer_receivables` | `receivable_entries` | `belongsTo` | `customer_receivable_id` | `CASCADE` | *غير محدد* |
| `payments` | `receivable_entries` | `belongsTo` | `payment_id` | `SET NULL` | *غير محدد* |
| `payment_allocations`| `receivable_entries` | `belongsTo` | `payment_allocation_id` | `SET NULL` | *غير محدد* |
| `users` | `receivable_entries` | `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `customer_receivable_id`, `entry_date`, `amount`, `base_amount`, `entry_type`, `created_by`, `created_at`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `entry_date` = `CURRENT_TIMESTAMP`, `entry_type` = `'Payment'`, `created_at` = `CURRENT_TIMESTAMP`
- **CHECK Constraints:** `chk_re_type` (`entry_type IN ('Payment', 'Adjustment', 'WriteOff')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `string(20)` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** سجلات دفع وسداد الذمم هي عمليات مالية يومية تتم في الفروع ويجب مزامنتها مع الخادم المركزي لتوثيق التسويات والتحصيلات.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## Final Verification Report

- Sales Tables ............. PASS
- Columns Extraction ....... PASS
- Relationships ............ PASS
- Constraints .............. PASS
- Type Mapping ............. PASS
- SQLite Compatibility ..... PASS
- Architecture Compliance .. PASS

**Ready For Drift Generation — Phase 4 ✅**
