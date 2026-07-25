# SQLite Schema Extraction
## Phase 2 — Inventory Foundation Tables
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`
**Date:** 2026-07-18

---

## 1. Table: `warehouses`

### 1. General Information
- **Table Name:** `warehouses`
- **Purpose:** Storage locations linked to a branch. Each branch can have a default warehouse.
- **Domain:** DOMAIN 3 — INVENTORY
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `branch_id` | `uuid` | No | — | Composite FK |
| `warehouse_name` | `string(255)` | No | — | |
| `warehouse_code` | `string(100)` | No | — | |
| `address` | `string(255)` | Yes | — | |
| `is_default` | `boolean` | No | `false` | |
| `is_active` | `boolean` | No | `true` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |
| `deleted_at` | `timestamp` | Yes | — | Soft Delete |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `(business_id, branch_id)` → `branches` (RESTRICT)
- **Composite Keys:** `(business_id, branch_id)`
- **Unique Constraints:** `(business_id, id)`, `(business_id, warehouse_code)`, partial unique `uq_warehouses_default_branch` (`business_id`, `branch_id`) WHERE `is_default = TRUE`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `warehouses` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `branches` | `warehouses` | `belongsTo` | `branch_id` | `RESTRICT` | *غير محدد* |

*(Note: The table `warehouses` also acts as a parent for `inventories`, `inventory_transactions`, `inventory_transfers`, etc. via `hasMany`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, warehouse_code)`
- **Partial Unique Index:** `uq_warehouses_default_branch`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `branch_id`, `warehouse_name`, `warehouse_code`, `is_default`, `is_active`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, warehouse_code)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `is_default` = `false`, `is_active` = `true`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(255)` / `(100)` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** جدول تشغيلي محلي يسمح للمستخدم بإنشاء مستودعات وتعديلها من أجهزة الفروع ويحتاج للمزامنة ثنائية الاتجاه (Bidirectional) مع السحابة وباقي الأجهزة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 2. Table: `inventories`

### 1. General Information
- **Table Name:** `inventories`
- **Purpose:** Current stock levels per warehouse per product_unit. Single source of truth for on-hand quantity.
- **Domain:** DOMAIN 3 — INVENTORY
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `warehouse_id` | `uuid` | No | — | FK → warehouses |
| `product_unit_id` | `uuid` | No | — | FK → product_units |
| `quantity` | `decimal(18,3)` | No | `0.000` | CHECK: >= 0 |
| `average_cost` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `alert_quantity` | `decimal(18,3)` | No | `0.000` | CHECK: >= 0 |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |
| `deleted_at` | `timestamp` | Yes | — | Soft Delete |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `warehouse_id` → `warehouses.id` (RESTRICT), `product_unit_id` → `product_units.id` (RESTRICT)
- **Composite Keys:** `(business_id, warehouse_id, product_unit_id)`
- **Unique Constraints:** `(business_id, warehouse_id, product_unit_id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `inventories` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `warehouses` | `inventories` | `belongsTo` | `warehouse_id` | `RESTRICT` | *غير محدد* |
| `product_units` | `inventories` | `belongsTo` | `product_unit_id`| `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, warehouse_id, product_unit_id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `warehouse_id`, `product_unit_id`, `quantity`, `average_cost`, `alert_quantity`
- **UNIQUE Constraints:** `(business_id, warehouse_id, product_unit_id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `quantity` = `0.000`, `average_cost` = `0.00`, `alert_quantity` = `0.000`
- **CHECK Constraints:** `chk_inventories_values` (quantity >= 0, average_cost >= 0, alert_quantity >= 0)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,3)` / `(18,2)` | `REAL` | `RealColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** الأرصدة المخزنية تتغير يومياً وبشكل مستمر محلياً بناءً على المبيعات والتوريدات. تحتاج الأعمدة التزامنية لتحديث الرصيد التراكمي وفض النزاعات.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 3. Table: `inventory_transactions`

### 1. General Information
- **Table Name:** `inventory_transactions`
- **Purpose:** Header record for inventory movements (receipts, dispatches, adjustments, opening balances).
- **Domain:** DOMAIN 3 — INVENTORY
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `branch_id` | `uuid` | No | — | Composite FK |
| `warehouse_id` | `uuid` | No | — | Composite FK |
| `transaction_type` | `string(20)` | No | — | CHECK: Receipt, Dispatch, Adjustment In, Adjustment Out, Opening Balance |
| `movement_direction`| `string(3)` | No | — | CHECK: IN, OUT |
| `status` | `string(20)` | No | `'Draft'` | CHECK: Draft, Posted, Reversed |
| `reference_type` | `string(50)` | Yes | — | CHECK: SalesInvoice, SalesReturn, PurchaseInvoice, PurchaseReturn, Transfer, Adjustment or NULL |
| `reference_id` | `uuid` | Yes | — | Polymorphic reference |
| `transaction_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `created_by` | `uuid` | No | — | FK → users |
| `posted_by` | `uuid` | Yes | — | FK → users |
| `posted_at` | `timestamp` | Yes | — | |
| `reversed_by` | `uuid` | Yes | — | FK → users |
| `reversed_at` | `timestamp` | Yes | — | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, branch_id)` → `branches` (RESTRICT), `(business_id, warehouse_id)` → `warehouses` (RESTRICT), `created_by` → `users.id` (RESTRICT), `posted_by` → `users.id` (RESTRICT), `reversed_by` → `users.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `branches` | `inventory_transactions` | `belongsTo` | `branch_id` | `RESTRICT` | *غير محدد* |
| `warehouses` | `inventory_transactions` | `belongsTo` | `warehouse_id` | `RESTRICT` | *غير محدد* |
| `users` | `inventory_transactions` | `belongsTo` | `created_by` / `posted_by` / `reversed_by`| `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `InventoryTransactionLine`).*

### 5. Indexes
- **Indexes:** `idx_inv_tx_reference` on `(reference_type, reference_id)`
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `branch_id`, `warehouse_id`, `transaction_type`, `movement_direction`, `status`, `transaction_date`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `status` = `'Draft'`, `transaction_date` = `CURRENT_TIMESTAMP`
- **CHECK Constraints:** `chk_inv_tx_status`, `chk_inv_tx_type`, `chk_inv_tx_movement`, `chk_inv_tx_ref`

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(20)` / `(3)` / `(50)`| `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** هذا الجدول يسجل المعاملات اليومية التي تنشأ من الأجهزة المحلية وتحتاج إلى مزامنة دورية لضمان سلامة مخزون السحابة والمطابقة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 4. Table: `inventory_transaction_lines`

### 1. General Information
- **Table Name:** `inventory_transaction_lines`
- **Purpose:** Line items for inventory transactions specifying product, quantity, and cost.
- **Domain:** DOMAIN 3 — INVENTORY
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `inventory_transaction_id`| `uuid` | No | — | Composite FK |
| `product_unit_id` | `uuid` | No | — | Composite FK |
| `line_number` | `integer` | No | `1` | |
| `quantity` | `decimal(18,3)` | No | — | CHECK: > 0 |
| `unit_cost` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, inventory_transaction_id)` → `inventory_transactions` (CASCADE), `(business_id, product_unit_id)` → `product_units` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** None

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `inventory_transactions`| `inventory_transaction_lines`| `belongsTo` | `inventory_transaction_id` | `CASCADE` | *غير محدد* |
| `product_units` | `inventory_transaction_lines`| `belongsTo` | `product_unit_id` | `RESTRICT` | *غير محدد* |

### 5. Indexes
*غير موجودة بشكل صريح في الوثيقة باستثناء المفاتيح الأساسية والخارجية.*

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `inventory_transaction_id`, `product_unit_id`, `line_number`, `quantity`, `unit_cost`
- **UNIQUE Constraints:** None
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `line_number` = `1`, `unit_cost` = `0.00`
- **CHECK Constraints:** `chk_inv_tx_line_qty` (`> 0`), `chk_inv_tx_line_cost` (`>= 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `integer` | `INTEGER` | `IntColumn` |
| `decimal(18,3)` / `(18,2)` | `REAL` | `RealColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تابعة بشكل وثيق للـ Transaction Header وكل بند يجب أن يخضع لنظام النسخ المحلي والمزامنة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 5. Table: `inventory_transfers`

### 1. General Information
- **Table Name:** `inventory_transfers`
- **Purpose:** Header for stock transfer between warehouses within the same business.
- **Domain:** DOMAIN 3 — INVENTORY
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses |
| `from_warehouse_id` | `uuid` | No | — | Composite FK |
| `to_warehouse_id` | `uuid` | No | — | Composite FK |
| `transfer_number` | `string(50)` | No | — | |
| `transfer_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `status` | `string(20)` | No | `'Pending'` | CHECK: Pending, Completed, Cancelled |
| `notes` | `text` | Yes | — | |
| `created_by` | `uuid` | No | — | FK → users |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `(business_id, from_warehouse_id)` → `warehouses` (RESTRICT), `(business_id, to_warehouse_id)` → `warehouses` (RESTRICT), `created_by` → `users.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, transfer_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `inventory_transfers` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `warehouses` | `inventory_transfers` | `belongsTo` | `from_warehouse_id` | `RESTRICT` | *غير محدد* |
| `warehouses` | `inventory_transfers` | `belongsTo` | `to_warehouse_id` | `RESTRICT` | *غير محدد* |
| `users` | `inventory_transfers` | `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, transfer_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `from_warehouse_id`, `to_warehouse_id`, `transfer_number`, `transfer_date`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, transfer_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `transfer_date` = `CURRENT_TIMESTAMP`, `status` = `'Pending'`
- **CHECK Constraints:** `chk_inv_transfers_status`, `chk_inv_transfers_wh` (from ≠ to)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(20)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** من مهام إدارة المخزون المحلي تحويل المخزون بين الفروع بشكل يومي، وهذه الحركات يجب أن تخضع للمزامنة للموافقة عليها.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 6. Table: `inventory_transfer_items`

### 1. General Information
- **Table Name:** `inventory_transfer_items`
- **Purpose:** Line items for inventory transfers specifying product, quantity, and cost.
- **Domain:** DOMAIN 3 — INVENTORY
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `transfer_id` | `uuid` | No | — | Composite FK |
| `product_unit_id` | `uuid` | No | — | Composite FK |
| `quantity` | `decimal(18,3)` | No | — | CHECK: > 0 |
| `unit_cost` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, transfer_id)` → `inventory_transfers` (CASCADE), `(business_id, product_unit_id)` → `product_units` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(transfer_id, product_unit_id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `inventory_transfers`| `inventory_transfer_items`| `belongsTo` | `transfer_id` | `CASCADE` | *غير محدد* |
| `product_units` | `inventory_transfer_items`| `belongsTo` | `product_unit_id` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(transfer_id, product_unit_id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `transfer_id`, `product_unit_id`, `quantity`, `unit_cost`
- **UNIQUE Constraints:** `(transfer_id, product_unit_id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `unit_cost` = `0.00`
- **CHECK Constraints:** `chk_inv_ti_values` (`quantity > 0, unit_cost >= 0`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,3)` / `(18,2)` | `REAL` | `RealColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تابعة لبيانات الـ Transfer ويجب مزامنتها مع تفاصيل البنود والكميات.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 7. Table: `stock_adjustments`

### 1. General Information
- **Table Name:** `stock_adjustments`
- **Purpose:** Inventory physical count adjustment headers (increases, decreases, damage, loss).
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (From original schema context)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (RESTRICT) |
| `warehouse_id` | `uuid` | No | — | Composite FK |
| `adjustment_number` | `string(50)` | No | — | |
| `adjustment_date` | `timestamp` | No | `CURRENT_TIMESTAMP` | |
| `adjustment_type` | `string(20)` | No | — | CHECK: Increase, Decrease, Damage, Loss |
| `status` | `string(20)` | No | `'Draft'` | CHECK: Draft, Posted |
| `notes` | `text` | Yes | — | |
| `created_by` | `uuid` | No | — | FK → users (RESTRICT) |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |
| `deleted_at` | `timestamp` | Yes | — | Soft Delete |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (RESTRICT), `(business_id, warehouse_id)` → `warehouses` (RESTRICT), `created_by` → `users.id` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, adjustment_number)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `stock_adjustments` | `belongsTo` | `business_id` | `RESTRICT` | *غير محدد* |
| `warehouses` | `stock_adjustments` | `belongsTo` | `warehouse_id` | `RESTRICT` | *غير محدد* |
| `users` | `stock_adjustments` | `belongsTo` | `created_by` | `RESTRICT` | *غير محدد* |

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, adjustment_number)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `warehouse_id`, `adjustment_number`, `adjustment_date`, `adjustment_type`, `status`, `created_by`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, adjustment_number)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `adjustment_date` = `CURRENT_TIMESTAMP`, `status` = `'Draft'`
- **CHECK Constraints:** `chk_sa_type`, `chk_sa_status`

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(20)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** التسويات المخزنية الدورية للمستودعات تُجرى محلياً وتحتاج الرفع للسحابة لمطابقة العهد والجرد الفعلي.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 8. Table: `stock_adjustment_items`

### 1. General Information
- **Table Name:** `stock_adjustment_items`
- **Purpose:** Line items for stock adjustments comparing system quantity vs physical quantity.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (From original schema context)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `adjustment_id` | `uuid` | No | — | Composite FK |
| `product_unit_id` | `uuid` | No | — | Composite FK |
| `system_qty` | `decimal(18,3)` | No | — | |
| `physical_qty` | `decimal(18,3)` | No | — | |
| `diff_qty` | `decimal(18,3)` | No | — | CHECK: diff_qty = physical_qty - system_qty |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `(business_id, adjustment_id)` → `stock_adjustments` (CASCADE), `(business_id, product_unit_id)` → `product_units` (RESTRICT)
- **Composite Keys:** None
- **Unique Constraints:** None

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `stock_adjustments`| `stock_adjustment_items`| `belongsTo` | `adjustment_id` | `CASCADE` | *غير محدد* |
| `product_units` | `stock_adjustment_items`| `belongsTo` | `product_unit_id` | `RESTRICT` | *غير محدد* |

### 5. Indexes
*غير موجودة باستثناء المفاتيح الأساسية والخارجية.*

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `adjustment_id`, `product_unit_id`, `system_qty`, `physical_qty`, `diff_qty`
- **UNIQUE Constraints:** None
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`
- **CHECK Constraints:** `chk_sai_diff` (`diff_qty = physical_qty - system_qty`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,3)` | `REAL` | `RealColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** تابعة لبيانات الـ Adjustment ويجب مزامنتها مع السحابة لتحديث سجل الفروقات.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## Final Verification Report

- Inventory Tables ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

**Ready For Drift Generation — Phase 2 ✅**
