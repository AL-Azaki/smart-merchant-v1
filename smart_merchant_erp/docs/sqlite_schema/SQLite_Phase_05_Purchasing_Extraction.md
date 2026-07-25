# SQLite Schema Extraction
## Phase 5 — Purchasing & Supplier Management
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`
**Date:** 2026-07-18

---

## Architecture Compliance & Single Source of Truth Mandate

> [!IMPORTANT]
> **Single Source of Truth Mandate for Purchasing & Suppliers:**
> تطبيق **Flutter SQLite ERP** هو المصدر الرسمي والوحيد (Single Source of Truth) لجميع عمليات المشتريات وإدارة الموردين، وتشمل:
> (إنشاء وتعديل وأرشفة الموردين، إنشاء فواتير الشراء، مرتجعات الشراء، إدارة الذمم الدائنة، تسجيل مدفوعات الموردين، وتحديث أرصدة الموردين).
> 
> **مسؤولية Laravel PostgreSQL:**  
> ليس مسؤولاً عن تنفيذ أو إدارة عمليات الشراء، وتقتصر مسؤوليته فقط على: استقبال البيانات بعد المزامنة، حفظ النسخة السحابية، التقارير المركزية، لوحة التحكم Dashboard، والتحليلات.
>
> **اتجاه المزامنة الرسمي:**  
> `Flutter SQLite ERP` → `Sync Engine` → `Laravel PostgreSQL` → `Dashboard / Reporting`
> 
> عند ظهور جداول سبق استخراجها أو جداول خارجية في العلاقات (`businesses`, `branches`, `users`, `currencies`, `products`, `product_units`, `warehouses`, `chart_of_accounts`, `payment_terms`, `taxes` إلخ)، يتم توثيق العلاقة فقط كمرجع دون إعادة استخراجها أو نسخ أعمدتها.

---

## 1. Table: `suppliers`

### 1. General Information
- **Table Name:** `suppliers`
- **Purpose:** Supplier master data with credit terms, opening balances, and linked accounting accounts.
- **Domain:** DOMAIN 4 — PURCHASING & SUPPLIERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `supplier_name` | `string(255)` | No | — | |
| `contact_person`| `string(255)` | Yes | — | |
| `phone` | `string(30)` | Yes | — | |
| `supplier_address`| `string(255)` | Yes | — | |
| `default_currency_id`| `uuid` | Yes | — | FK → currencies (NULL ON DELETE) |
| `payment_term_id` | `uuid` | Yes | — | Composite FK |
| `payable_account_id`| `uuid` | Yes | — | Composite FK → chart_of_accounts |
| `credit_limit` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `opening_balance` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `opening_balance_type`| `string(10)` | Yes | — | CHECK: debit, credit |
| `opening_balance_date`| `date` | Yes | — | |
| `is_active` | `boolean` | No | `true` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |
| `deleted_at` | `timestamp` | Yes | — | Soft Delete |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `default_currency_id` → `currencies.id` (NULL), `(business_id, payment_term_id)` → `payment_terms` (RESTRICT), `(business_id, payable_account_id)` → `chart_of_accounts` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `suppliers` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `suppliers` | `belongsTo` | `default_currency_id` | `SET NULL` | *غير محدد* |
| `payment_terms` | `suppliers` | `belongsTo` | `payment_term_id` | `RESTRICT` | *غير محدد* |
| `chart_of_accounts`| `suppliers` | `belongsTo` | `payable_account_id` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `PurchaseInvoice`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `supplier_name`, `credit_limit`, `opening_balance`, `is_active`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `credit_limit` = `0.00`, `opening_balance` = `0.00`, `is_active` = `true`
- **CHECK Constraints:** `chk_sup_credit` (`credit_limit >= 0`), `chk_sup_balance` (`opening_balance >= 0`), `chk_sup_bal_type` (`opening_balance_type IN ('debit', 'credit')`), `chk_sup_bal_req` (`opening_balance > 0` requires `opening_balance_type`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(255)` / `(30)` / `(10)` | `TEXT` | `TextColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** بيانات الموردين تُنشأ وتُدار محلياً داخل تطبيق الـ ERP (Source of Truth)، وتحتاج إلى المزامنة المستمرة مع السحابة لضمان اتساق الأرصدة والبيانات الأساسية للموردين.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 2. Table: `purchase_invoices`

### 1. General Information
- **Table Name:** `purchase_invoices`
- **Purpose:** Purchase invoice headers with multi-currency support, dual totals (foreign + base), and audit trail.
- **Domain:** DOMAIN 4 — PURCHASING & SUPPLIERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `branch_id` | `uuid` | No | — | Composite FK |
| `supplier_id` | `uuid` | No | — | Composite FK |
| `warehouse_id` | `uuid` | No | — | Composite FK |
| `invoice_number` | `string(50)` | No | — | |
| `purchase_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `due_date` | `timestamp` | Yes | — | CHECK: >= purchase_date |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `exchange_rate` | `decimal(18,8)` | No | `1.00000000` | |
| `sub_total` | `decimal(18,2)` | No | `0.00` | |
| `discount_total` | `decimal(18,2)` | No | `0.00` | |
| `tax_total` | `decimal(18,2)` | No | `0.00` | |
| `grand_total` | `decimal(18,2)` | No | `0.00` | |
| `base_sub_total` | `decimal(18,2)` | No | `0.00` | |
| `base_discount_total`| `decimal(18,2)` | No | `0.00` | |
| `base_tax_total` | `decimal(18,2)` | No | `0.00` | |
| `base_grand_total` | `decimal(18,2)` | No | `0.00` | |
| `payment_status` | `string(20)` | No | `'Unpaid'` | CHECK: Unpaid, Partial, Paid |
| `status` | `string(20)` | No | `'Draft'` | CHECK: Draft, Posted, Reversed |
| `notes` | `text` | Yes | — | |
| `created_by` | `uuid` | No | — | FK → users |
| `posted_by` | `uuid` | Yes | — | FK → users |
| `posted_at` | `timestamp` | Yes | — | |
| `reversed_by` | `uuid` | Yes | — | FK → users |
| `reversed_at` | `timestamp` | Yes | — | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `created_by` → `users.id` (RESTRICT), `posted_by` → `users.id` (RESTRICT), `reversed_by` → `users.id` (RESTRICT), `(business_id, branch_id)` → `branches`, `(business_id, supplier_id)` → `suppliers`, `(business_id, warehouse_id)` → `warehouses`
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, invoice_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `purchase_invoices` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `branches` | `purchase_invoices` | `belongsTo` | `branch_id` | *غير محدد* | *غير محدد* |
| `suppliers` | `purchase_invoices` | `belongsTo` | `supplier_id` | *غير محدد* | *غير محدد* |
| `warehouses` | `purchase_invoices` | `belongsTo` | `warehouse_id` | *غير محدد* | *غير محدد* |
| `currencies` | `purchase_invoices` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `purchase_invoices` | `belongsTo` | `created_by` / `posted_by` / `reversed_by` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `PurchaseInvoiceItem` and `PurchaseReturn`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, invoice_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `branch_id`, `supplier_id`, `warehouse_id`, `invoice_number`, `purchase_date`, `currency_id`, `exchange_rate`, `sub_total`, `discount_total`, `tax_total`, `grand_total`, `base_sub_total`, `base_discount_total`, `base_tax_total`, `base_grand_total`, `payment_status`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, invoice_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `purchase_date` = `CURRENT_TIMESTAMP`, `exchange_rate` = `1.00000000`, numeric totals = `0.00`, `payment_status` = `'Unpaid'`, `status` = `'Draft'`
- **CHECK Constraints:** `chk_pi_payment` (`payment_status IN ('Unpaid', 'Partial', 'Paid')`), `chk_pi_status` (`status IN ('Draft', 'Posted', 'Reversed')`), `chk_pi_dates` (`due_date >= purchase_date`)

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
- **السبب:** عمليات شراء البضائع وإدخال فواتير المشتريات تتم من الفروع محلياً وتؤدي لتحديث المخزون والذمم، وتتطلب الرفع للسحابة وحفظ سجل المزامنة وتجنب التعارضات.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 3. Table: `purchase_invoice_items`

### 1. General Information
- **Table Name:** `purchase_invoice_items`
- **Purpose:** Line items for purchase invoices.
- **Domain:** DOMAIN 4 — PURCHASING & SUPPLIERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `purchase_invoice_id`| `uuid` | No | — | Composite FK |
| `product_unit_id` | `uuid` | No | — | Composite FK |
| `warehouse_id` | `uuid` | No | — | Composite FK |
| `tax_id` | `uuid` | Yes | — | No FK constraint (commented out in original) |
| `quantity` | `decimal(18,3)` | No | — | CHECK: > 0 |
| `unit_price` | `decimal(18,2)` | No | — | CHECK: >= 0 |
| `discount` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `tax` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `line_total` | `decimal(18,2)` | No | — | CHECK: >= 0 |
| `base_line_total` | `decimal(18,2)` | No | `0.00` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, purchase_invoice_id)` → `purchase_invoices` (CASCADE), `(business_id, product_unit_id)` → `product_units` (RESTRICT), `(business_id, warehouse_id)` → `warehouses` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `purchase_invoices` | `purchase_invoice_items`| `belongsTo` | `purchase_invoice_id` | `CASCADE` | *غير محدد* |
| `product_units` | `purchase_invoice_items`| `belongsTo` | `product_unit_id` | `RESTRICT` | *غير محدد* |
| `warehouses` | `purchase_invoice_items`| `belongsTo` | `warehouse_id` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `PurchaseReturnItem`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `purchase_invoice_id`, `product_unit_id`, `warehouse_id`, `quantity`, `unit_price`, `discount`, `tax`, `line_total`, `base_line_total`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `discount` = `0.00`, `tax` = `0.00`, `base_line_total` = `0.00`
- **CHECK Constraints:** `chk_pi_item_quantity` (`quantity > 0`), `chk_pi_item_price` (`unit_price >= 0`), `chk_pi_item_discount` (`discount >= 0`), `chk_pi_item_tax` (`tax >= 0`), `chk_pi_item_total` (`line_total >= 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,3)` / `(18,2)` | `REAL` | `RealColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تابعة مباشرة لرأس فاتورة الشراء وتُسجل محلياً لضمان إدخال الكميات وأسعار التكلفة للمستودع وتتطلب الرفع للمزامنة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 4. Table: `purchase_returns`

### 1. General Information
- **Table Name:** `purchase_returns`
- **Purpose:** Purchase return headers linked to a purchase invoice.
- **Domain:** DOMAIN 4 — PURCHASING & SUPPLIERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `branch_id` | `uuid` | No | — | Composite FK |
| `purchase_invoice_id`| `uuid` | No | — | Composite FK |
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
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `created_by` → `users.id` (RESTRICT), `(business_id, branch_id)` → `branches`, `(business_id, purchase_invoice_id)` → `purchase_invoices`
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, return_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `purchase_returns` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `branches` | `purchase_returns` | `belongsTo` | `branch_id` | *غير محدد* | *غير محدد* |
| `purchase_invoices`| `purchase_returns` | `belongsTo` | `purchase_invoice_id` | *غير محدد* | *غير محدد* |
| `currencies` | `purchase_returns` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |
| `users` | `purchase_returns` | `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `PurchaseReturnItem`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, return_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `branch_id`, `purchase_invoice_id`, `return_number`, `return_date`, `currency_id`, `exchange_rate`, `total_amount`, `base_total_amount`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, return_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `return_date` = `CURRENT_TIMESTAMP`, `exchange_rate` = `1.00000000`, totals = `0.00`, `status` = `'Draft'`
- **CHECK Constraints:** None (Has DB trigger `trg_purchase_return_qty` in PostgreSQL to validate return qty <= purchased qty).

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
- **السبب:** مرتجعات المشتريات تُنشأ وتُعتمد محلياً لخصم المخزون وتخفيض ذمة المورد الدائنة، وتحتاج المزامنة لتوثيق الحركة سحابياً.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 5. Table: `purchase_return_items`

### 1. General Information
- **Table Name:** `purchase_return_items`
- **Purpose:** Line items for purchase returns, linked to original purchase invoice items.
- **Domain:** DOMAIN 4 — PURCHASING & SUPPLIERS
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `purchase_return_id`| `uuid` | No | — | Composite FK |
| `purchase_invoice_item_id`| `uuid`| No | — | FK → purchase_invoice_items |
| `warehouse_id` | `uuid` | No | — | Composite FK |
| `quantity` | `decimal(18,3)` | No | — | |
| `unit_price` | `decimal(18,2)` | No | — | |
| `line_total` | `decimal(18,2)` | No | — | |
| `base_line_total` | `decimal(18,2)` | No | `0.00` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, purchase_return_id)` → `purchase_returns` (CASCADE), `purchase_invoice_item_id` → `purchase_invoice_items.id` (RESTRICT), `(business_id, warehouse_id)` → `warehouses` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `purchase_returns` | `purchase_return_items`| `belongsTo` | `purchase_return_id` | `CASCADE` | *غير محدد* |
| `purchase_invoice_items`| `purchase_return_items`| `belongsTo` | `purchase_invoice_item_id`| `RESTRICT` | *غير محدد* |
| `warehouses` | `purchase_return_items`| `belongsTo` | `warehouse_id` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `purchase_return_id`, `purchase_invoice_item_id`, `warehouse_id`, `quantity`, `unit_price`, `line_total`, `base_line_total`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `base_line_total` = `0.00`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,3)` / `(18,2)` | `REAL` | `RealColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تابعة لرأس حركة المرتجع وتُسجل معها محلياً لضمان ضبط كميات الأصناف المرتجعة للمورد ومزامنتها.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 6. Table: `supplier_payables`

### 1. General Information
- **Table Name:** `supplier_payables`
- **Purpose:** Accounts Payable (A/P) sub-ledger tracking open purchase invoices, paid amounts, due dates, and aging per supplier.
- **Domain:** DOMAIN 4 — PURCHASING & SUPPLIERS (Accounts Payable)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (RESTRICT) |
| `supplier_id` | `uuid` | No | — | Composite FK → suppliers (RESTRICT) |
| `purchase_invoice_id`| `uuid` | No | — | Composite FK → purchase_invoices (RESTRICT) |
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
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `currency_id` → `currencies.id` (RESTRICT), `(business_id, supplier_id)` → `suppliers` (RESTRICT), `(business_id, purchase_invoice_id)` → `purchase_invoices` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, purchase_invoice_id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `supplier_payables` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `suppliers` | `supplier_payables` | `belongsTo` | `supplier_id` | `RESTRICT` | *غير محدد* |
| `purchase_invoices`| `supplier_payables` | `belongsTo` | `purchase_invoice_id` | `RESTRICT` | *غير محدد* |
| `currencies` | `supplier_payables` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `PayableEntry`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, purchase_invoice_id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `supplier_id`, `purchase_invoice_id`, `currency_id`, `exchange_rate`, `original_amount`, `base_original_amount`, `paid_amount`, `base_paid_amount`, `remaining_amount`, `base_remaining_amount`, `status`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, purchase_invoice_id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `exchange_rate` = `1.00000000`, `paid_amount` = `0.00`, `base_paid_amount` = `0.00`, `status` = `'Unpaid'`
- **CHECK Constraints:** `chk_sp_status` (`status IN ('Unpaid', 'Partial', 'Paid')`)

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
- **السبب:** إدارة ذمم الموردين ومستحقاتهم هي جزء أساسي من عمليات الشراء المحلية (Source of Truth)، وتتطلب المزامنة مع السحابة لتعقب المدفوعات والأرصدة الدائنة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 7. Table: `payable_entries`

### 1. General Information
- **Table Name:** `payable_entries`
- **Purpose:** Detailed tracking history of payment allocations against accounts payable records.
- **Domain:** DOMAIN 4 — PURCHASING & SUPPLIERS (Accounts Payable)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `supplier_payable_id` | `uuid` | No | — | Composite FK → supplier_payables (CASCADE) |
| `payment_id` | `uuid` | Yes | — | Composite FK → payments (SET NULL) |
| `payment_allocation_id`| `uuid` | Yes | — | Composite FK → payment_allocations (SET NULL) |
| `entry_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `amount` | `decimal(18,2)` | No | — | |
| `base_amount` | `decimal(18,2)` | No | — | |
| `entry_type` | `string(20)` | No | `'Payment'` | CHECK: Payment, Adjustment, WriteOff |
| `created_by` | `uuid` | No | — | FK → users (RESTRICT) |
| `created_at` | `timestamp` | No | `CURRENT_TIMESTAMP` | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, supplier_payable_id)` → `supplier_payables` (CASCADE), `(business_id, payment_id)` → `payments` (SET NULL), `(business_id, payment_allocation_id)` → `payment_allocations` (SET NULL), `created_by` → `users.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `supplier_payables` | `payable_entries` | `belongsTo` | `supplier_payable_id` | `CASCADE` | *غير محدد* |
| `payments` | `payable_entries` | `belongsTo` | `payment_id` | `SET NULL` | *غير محدد* |
| `payment_allocations`| `payable_entries` | `belongsTo` | `payment_allocation_id`| `SET NULL` | *غير محدد* |
| `users` | `payable_entries` | `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `supplier_payable_id`, `entry_date`, `amount`, `base_amount`, `entry_type`, `created_by`, `created_at`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `entry_date` = `CURRENT_TIMESTAMP`, `entry_type` = `'Payment'`, `created_at` = `CURRENT_TIMESTAMP`
- **CHECK Constraints:** `chk_pe_type` (`entry_type IN ('Payment', 'Adjustment', 'WriteOff')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `string(20)` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** سجلات دفع وسداد ذمم الموردين تُجرى محلياً عند إصدار سندات الصرف للموردين، وتحتاج للرفع الدوري للمزامنة مع الخادم.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## Final Verification Report

- Purchasing Tables ........ PASS
- Columns Extraction ....... PASS
- Relationships ............ PASS
- Constraints .............. PASS
- Type Mapping ............. PASS
- SQLite Compatibility ..... PASS
- Architecture Compliance .. PASS

**Ready For Drift Generation — Phase 5 ✅**
