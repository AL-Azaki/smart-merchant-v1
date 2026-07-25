# SQLite Schema Extraction
## Phase 03 — Catalog Module (Full Extraction & Architecture Specification)

**Project:** Smart Merchant ERP  
**Source of Truth:** `Database_Schema_Extraction.md`  
**Date:** 2026-07-19  

---

## Architectural Mandate & Data Governance

```
Flutter (SQLite)
        │
        │
        ├── Source of Truth
        ├── جميع عمليات الإنشاء
        ├── جميع عمليات التعديل
        ├── جميع عمليات الحذف
        ├── جميع بيانات الكتالوج
        ├── جميع بيانات المخزون
        ├── جميع بيانات التشغيل
        │
        ▼
Sync Engine
        │
        ▼
Laravel PostgreSQL
        │
        ├── Cloud Replica
        ├── Synchronization Target
        ├── Admin Dashboard
        ├── REST API
        ├── E-Commerce
        ├── Published Catalog
        └── Reporting
```

- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

جميع البيانات المتعلقة بالمنتجات والتصنيفات والعلامات التجارية والوحدات والأسعار والضرائب والمتغيرات والصور يتم إنشاؤها وإدارتها وتعديلها وحذفها حصرياً داخل التطبيق المحلي (`Flutter SQLite` كـ **Source of Truth**).  
يتم مزامنة كافة الجداول وحركاتها إلى `Laravel PostgreSQL` الذي يعمل فقط كـ **Cloud Replica** و **Synchronization Target** و **Published Catalog** لخدمة لوحة الإدارة والمتجر الإلكتروني والتقارير.

---

## 1. Table: `categories`

### 1. General Information & Ownership
- **Table Name:** `categories`
- **Description:** Product categories with self-referencing parent for hierarchical classification and e-commerce display, scoped per business.
- **Module:** DOMAIN 2 — CATALOG
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | Primary Key |
| `business_id` | `uuid` | No | — | Foreign Key linking to `businesses.id` |
| `parent_id` | `uuid` | Yes | — | Self-referential Composite Foreign Key |
| `category_name` | `string(100)` | No | — | Category display name |
| `category_code` | `string(50)` | Yes | — | Unique category reference code |
| `description` | `text` | Yes | — | Category detailed notes |
| `image_path` | `string(500)` | Yes | — | Relative path to category icon or banner |
| `sort_order` | `integer` | No | `0` | Numerical sorting sequence |
| `is_active` | `boolean` | No | `true` | Operational activity flag |
| `created_at` | `timestamp` | Yes | — | Record creation timestamp |
| `updated_at` | `timestamp` | Yes | — | Record last update timestamp |
| `deleted_at` | `timestamp` | Yes | — | Soft delete timestamp |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` / `(50)` / `(500)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `integer` | `INTEGER` | `IntColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `id` (`TEXT` / UUID string)
- **Foreign Keys:** 
  - `business_id` → `businesses(id) ON DELETE RESTRICT`
  - Composite `(business_id, parent_id)` → `categories(business_id, id) ON DELETE RESTRICT`
- **Composite Keys:** `(business_id, parent_id)`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, category_name)`, `(business_id, category_code)`
- **CHECK Constraints:** `CHECK (sort_order >= 0)`
- **Default Values:** `sort_order = 0`, `is_active = true`

### 5. Enums & Type Converters
- **Enum Usage:** None
- **Type Converter Requirements:** Standard Drift primitive mappings.

### 6. Relationships
- `belongsTo` → `Business`, `Category` (self-referential parent category)
- `hasMany` → `Category` (child sub-categories), `Product`

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## 2. Table: `brands`

### 1. General Information & Ownership
- **Table Name:** `brands`
- **Description:** Product manufacturers or brands classification scoped per business.
- **Module:** DOMAIN 2 — CATALOG
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | Primary Key |
| `business_id` | `uuid` | No | — | Foreign Key linking to `businesses.id` |
| `brand_name` | `string(100)` | No | — | Brand display name |
| `description` | `text` | Yes | — | Brand details |
| `logo_path` | `string(500)` | Yes | — | Relative path to brand logo graphic |
| `is_active` | `boolean` | No | `true` | Operational status flag |
| `created_at` | `timestamp` | Yes | — | Record creation timestamp |
| `updated_at` | `timestamp` | Yes | — | Record last update timestamp |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` / `(500)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `id` (`TEXT` / UUID string)
- **Foreign Keys:** `business_id` → `businesses(id) ON DELETE RESTRICT`
- **Composite Keys:** None
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, brand_name)`
- **CHECK Constraints:** None
- **Default Values:** `is_active = true`

### 5. Enums & Type Converters
- **Enum Usage:** None
- **Type Converter Requirements:** Standard primitive columns.

### 6. Relationships
- `belongsTo` → `Business`
- `hasMany` → `Product`

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## 3. Table: `units`

### 1. General Information & Ownership
- **Table Name:** `units`
- **Description:** Units of measurement definitions (e.g., Piece, Kg, Box) scoped per business.
- **Module:** DOMAIN 2 — CATALOG
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | Primary Key |
| `business_id` | `uuid` | No | — | Foreign Key linking to `businesses.id` |
| `unit_name` | `string(100)` | No | — | Full unit name (e.g. Kilogram) |
| `unit_symbol` | `string(10)` | No | — | Short unit symbol (e.g. KG) |
| `unit_description` | `text` | Yes | — | Measurement notes |
| `is_active` | `boolean` | No | `true` | Operational status flag |
| `created_at` | `timestamp` | Yes | — | Record creation timestamp |
| `updated_at` | `timestamp` | Yes | — | Record last update timestamp |
| `deleted_at` | `timestamp` | Yes | — | Soft delete timestamp |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` / `(10)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `id` (`TEXT` / UUID string)
- **Foreign Keys:** `business_id` → `businesses(id) ON DELETE RESTRICT`
- **Composite Keys:** None
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, unit_name)`, `(business_id, unit_symbol)`
- **CHECK Constraints:** None
- **Default Values:** `is_active = true`

### 5. Enums & Type Converters
- **Enum Usage:** None
- **Type Converter Requirements:** Standard primitive columns.

### 6. Relationships
- `belongsTo` → `Business`
- `hasMany` → `ProductUnit`

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## 4. Table: `products`

### 1. General Information & Ownership
- **Table Name:** `products`
- **Description:** Master product definitions with category, brand, and tax linkage.
- **Module:** DOMAIN 2 — CATALOG
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | Primary Key |
| `business_id` | `uuid` | No | — | Foreign Key linking to `businesses.id` |
| `category_id` | `uuid` | Yes | — | Composite Foreign Key to category |
| `brand_id` | `uuid` | Yes | — | Composite Foreign Key to brand |
| `tax_id` | `uuid` | Yes | — | Reference to default tax |
| `product_type` | `string(50)` | No | `'standard'` | Product type classification |
| `product_code` | `string(100)` | No | — | Unique internal item code |
| `product_name` | `string(255)` | No | — | Item full descriptive name |
| `description` | `text` | Yes | — | Item detailed description |
| `is_active` | `boolean` | No | `true` | Activity flag |
| `created_at` | `timestamp` | Yes | — | Record creation timestamp |
| `updated_at` | `timestamp` | Yes | — | Record last update timestamp |
| `deleted_at` | `timestamp` | Yes | — | Soft delete timestamp |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(100)` / `(255)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `id` (`TEXT` / UUID string)
- **Foreign Keys:** 
  - `business_id` → `businesses(id) ON DELETE RESTRICT`
  - Composite `(business_id, category_id)` → `categories(business_id, id) ON DELETE RESTRICT`
  - Composite `(business_id, brand_id)` → `brands(business_id, id) ON DELETE RESTRICT`
- **Composite Keys:** `(business_id, category_id)`, `(business_id, brand_id)`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, product_code)`
- **CHECK Constraints:** `CHECK (product_type IN ('standard', 'service', 'composite'))`
- **Default Values:** `product_type = 'standard'`, `is_active = true`

### 5. Enums & Type Converters
- **Enum Usage:** Product type classifications (`standard`, `service`, `composite`).
- **Type Converter Requirements:** Can be mapped to string columns or explicit Dart enum converters.

### 6. Relationships
- `belongsTo` → `Business`, `Category`, `Brand`, `Tax`
- `hasMany` → `ProductUnit`, `ProductImage`, `ProductVariant`, `ProductTax`
- `hasOne` → `ProductUnit` (baseUnit where `is_base_unit = true`), `ProductImage` (primaryImage where `is_primary = true`)

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## 5. Table: `product_units`

### 1. General Information & Ownership
- **Table Name:** `product_units`
- **Description:** Product-unit combinations with pricing and conversion ratios. Each product can have multiple units (e.g., Piece, Box of 12).
- **Module:** DOMAIN 2 — CATALOG
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | Primary Key |
| `business_id` | `uuid` | No | — | Foreign Key linking to `businesses.id` |
| `product_id` | `uuid` | No | — | Composite Foreign Key to `products` |
| `unit_id` | `uuid` | No | — | Foreign Key to `units.id` |
| `sku` | `string(100)` | Yes | — | Stock Keeping Unit code |
| `barcode` | `string(100)` | Yes | — | Barcode string (EAN/UPC/QR) |
| `conversion_factor`| `decimal(18,4)` | No | `1.0000` | Multiplier relative to base unit |
| `purchase_price` | `decimal(18,2)` | No | `0.00` | Default cost price per unit |
| `selling_price` | `decimal(18,2)` | No | `0.00` | Default retail price per unit |
| `minimum_price` | `decimal(18,2)` | No | `0.00` | Floor selling price per unit |
| `is_base_unit` | `boolean` | No | `false` | Flag indicating the base conversion unit |
| `is_active` | `boolean` | No | `true` | Operational status flag |
| `created_at` | `timestamp` | Yes | — | Record creation timestamp |
| `updated_at` | `timestamp` | Yes | — | Record last update timestamp |
| `deleted_at` | `timestamp` | Yes | — | Soft delete timestamp |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` | `TEXT` | `TextColumn` |
| `decimal(18,4)` / `(18,2)` | `REAL` | `RealColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `id` (`TEXT` / UUID string)
- **Foreign Keys:** 
  - `business_id` → `businesses(id) ON DELETE RESTRICT`
  - `unit_id` → `units(id) ON DELETE RESTRICT`
  - Composite `(business_id, product_id)` → `products(business_id, id) ON DELETE CASCADE`
- **Composite Keys:** `(business_id, product_id)`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, barcode)`, `(business_id, sku)`, `(product_id, unit_id)`
- **Indexes:** Partial unique index `uq_product_units_one_base ON product_units (product_id) WHERE is_base_unit = true`
- **CHECK Constraints:** 
  - `chk_pu_conversion (conversion_factor > 0)`
  - `chk_pu_prices (purchase_price >= 0 AND selling_price >= minimum_price AND minimum_price >= 0)`
- **Default Values:** `conversion_factor = 1.0000`, `purchase_price = 0.00`, `selling_price = 0.00`, `minimum_price = 0.00`, `is_base_unit = false`, `is_active = true`

### 5. Enums & Type Converters
- **Enum Usage:** None
- **Type Converter Requirements:** Standard primitive columns.

### 6. Relationships
- `belongsTo` → `Business`, `Product`, `Unit`
- `hasMany` → `BranchProductPrice`, `Inventory`, `InventoryTransactionLine`, `ProductVariant`, `ProductTax`

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## 6. Table: `branch_product_prices`

### 1. General Information & Ownership
- **Table Name:** `branch_product_prices`
- **Description:** Branch-specific price overrides and POS price configurations for product units.
- **Module:** DOMAIN 2 — CATALOG
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | Primary Key |
| `business_id` | `uuid` | No | — | Composite Foreign Key |
| `branch_id` | `uuid` | No | — | Composite Foreign Key to branch |
| `product_unit_id` | `uuid` | No | — | Composite Foreign Key to product unit |
| `purchase_price` | `decimal(18,2)` | No | `0.00` | Branch-specific cost price |
| `selling_price` | `decimal(18,2)` | No | `0.00` | Branch-specific retail price |
| `minimum_price` | `decimal(18,2)` | No | `0.00` | Branch-specific minimum selling price |
| `is_active` | `boolean` | No | `true` | Activity flag |
| `created_at` | `timestamp` | Yes | — | Record creation timestamp |
| `updated_at` | `timestamp` | Yes | — | Record last update timestamp |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `id` (`TEXT` / UUID string)
- **Foreign Keys:** 
  - Composite `(business_id, branch_id)` → `branches(business_id, id) ON DELETE CASCADE`
  - Composite `(business_id, product_unit_id)` → `product_units(business_id, id) ON DELETE CASCADE`
- **Composite Keys:** `(business_id, branch_id)`, `(business_id, product_unit_id)`
- **UNIQUE Constraints:** `(branch_id, product_unit_id)`
- **CHECK Constraints:** `chk_bpp_prices (purchase_price >= 0 AND selling_price >= minimum_price AND minimum_price >= 0)`
- **Default Values:** `purchase_price = 0.00`, `selling_price = 0.00`, `minimum_price = 0.00`, `is_active = true`

### 5. Enums & Type Converters
- **Enum Usage:** None
- **Type Converter Requirements:** Standard primitive columns.

### 6. Relationships
- `belongsTo` → `Branch`, `ProductUnit`

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## 7. Table: `product_images`

### 1. General Information & Ownership
- **Table Name:** `product_images`
- **Description:** Product image gallery with primary image designation and ordering.
- **Module:** DOMAIN 2 — CATALOG
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | Primary Key |
| `product_id` | `uuid` | No | — | Foreign Key to `products.id` |
| `image_path` | `string(500)` | No | — | Relative path to image asset |
| `is_primary` | `boolean` | No | `false` | Primary display image flag |
| `created_at` | `timestamp` | No | `CURRENT_TIMESTAMP` | Record creation timestamp |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(500)` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `id` (`TEXT` / UUID string)
- **Foreign Keys:** `product_id` → `products(id) ON DELETE CASCADE`
- **Composite Keys:** None
- **UNIQUE Constraints:** Partial unique index `uq_product_images_primary ON product_images (product_id) WHERE is_primary = true`
- **CHECK Constraints:** None
- **Default Values:** `is_primary = false`, `created_at = CURRENT_TIMESTAMP`

### 5. Enums & Type Converters
- **Enum Usage:** None
- **Type Converter Requirements:** Standard primitive columns.

### 6. Relationships
- `belongsTo` → `Product`

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## 8. Table: `taxes`

### 1. General Information & Ownership
- **Table Name:** `taxes`
- **Description:** Tax rates definitions per business (e.g., VAT 15%, Zero-Rated) used across products and transactions.
- **Module:** DOMAIN 8 — EXTENDED DOMAINS / CATALOG (Pricing & Taxes)
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | Primary Key |
| `business_id` | `uuid` | No | — | Foreign Key linking to `businesses.id` |
| `tax_name` | `string(100)` | No | — | Display name of the tax rule |
| `tax_code` | `string(50)` | No | — | Unique internal reference code |
| `rate` | `decimal(8,4)` | No | — | Tax percentage or fixed value |
| `tax_type` | `string(20)` | No | `'Percentage'` | Calculation method |
| `is_default` | `boolean` | No | `false` | Default transaction application flag |
| `is_active` | `boolean` | No | `true` | Activity flag |
| `created_at` | `timestamp` | Yes | — | Record creation timestamp |
| `updated_at` | `timestamp` | Yes | — | Record last update timestamp |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` / `(50)` / `(20)` | `TEXT` | `TextColumn` |
| `decimal(8,4)` | `REAL` | `RealColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `id` (`TEXT` / UUID string)
- **Foreign Keys:** `business_id` → `businesses(id) ON DELETE CASCADE`
- **Composite Keys:** None
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, tax_code)`
- **CHECK Constraints:** 
  - `chk_tax_rate (rate >= 0)`
  - `chk_tax_type (tax_type IN ('Percentage', 'Fixed'))`
- **Default Values:** `tax_type = 'Percentage'`, `is_default = false`, `is_active = true`

### 5. Enums & Type Converters
- **Enum Usage:** Calculation method classification (`Percentage`, `Fixed`).
- **Type Converter Requirements:** Standard string or custom Dart enum mapping.

### 6. Relationships
- `belongsTo` → `Business`
- `hasMany` → `ProductTax`

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## 9. Table: `product_taxes` (Pivot)

### 1. General Information & Ownership
- **Table Name:** `product_taxes`
- **Description:** Many-to-many pivot associating product units with applicable tax definitions.
- **Module:** DOMAIN 8 — EXTENDED DOMAINS / CATALOG (Pricing & Taxes)
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `business_id` | `uuid` | No | — | Foreign Key linking to `businesses.id` |
| `product_unit_id`| `uuid` | No | — | Composite Foreign Key to `product_units` |
| `tax_id` | `uuid` | No | — | Composite Foreign Key to `taxes` |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `(business_id, product_unit_id, tax_id)` — Composite Primary Key
- **Foreign Keys:** 
  - `business_id` → `businesses(id) ON DELETE CASCADE`
  - Composite `(business_id, product_unit_id)` → `product_units(business_id, id) ON DELETE CASCADE`
  - Composite `(business_id, tax_id)` → `taxes(business_id, id) ON DELETE CASCADE`
- **Composite Keys:** `(business_id, product_unit_id, tax_id)`
- **UNIQUE Constraints:** Implicit via composite primary key.
- **CHECK Constraints:** None

### 5. Enums & Type Converters
- **Enum Usage:** None
- **Type Converter Requirements:** Standard text primitive columns.

### 6. Relationships
- `belongsToMany` pivot between `ProductUnit` and `Tax`

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## 10. Table: `product_variants`

### 1. General Information & Ownership
- **Table Name:** `product_variants`
- **Description:** Product attribute options and values (e.g., Size: Large, Color: Red) per product unit.
- **Module:** DOMAIN 8 — EXTENDED DOMAINS / CATALOG (Variants)
- **Owner:** `Flutter SQLite`
- **Role:** `Source of Truth`
- **Sync Destination:** `Laravel PostgreSQL`
- **Cloud Role:** `Cloud Replica`
- **Published Catalog:** `YES`

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | Primary Key |
| `business_id` | `uuid` | No | — | Foreign Key linking to `businesses.id` |
| `product_unit_id`| `uuid` | No | — | Composite Foreign Key to `product_units` |
| `variant_name` | `string(100)` | No | — | Attribute name (e.g. Color, Size) |
| `variant_value` | `string(100)` | No | — | Attribute value (e.g. Red, XL) |

### 3. SQLite Compatibility & Type Mapping
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` | `TEXT` | `TextColumn` |

### 4. Keys & Constraints
- **Primary Keys:** `id` (`TEXT` / UUID string)
- **Foreign Keys:** 
  - `business_id` → `businesses(id) ON DELETE CASCADE`
  - Composite `(business_id, product_unit_id)` → `product_units(business_id, id) ON DELETE CASCADE`
- **Composite Keys:** `(business_id, product_unit_id)`
- **UNIQUE Constraints:** `(product_unit_id, variant_name)`
- **CHECK Constraints:** None
- **Default Values:** None

### 5. Enums & Type Converters
- **Enum Usage:** None
- **Type Converter Requirements:** Standard primitive columns.

### 6. Relationships
- `belongsTo` → `Business`, `ProductUnit`

### 7. Offline Metadata & Sync Metadata
- **Requires Offline Metadata:** YES (`sync_status`, `version`, `device_id`)
- **Sync Direction:** Bidirectional sync (`Flutter SQLite` → `Sync Engine` → `Laravel PostgreSQL Replica`).

---

## Architecture Compliance

Flutter SQLite ............. Source of Truth ✅
Laravel PostgreSQL ......... Cloud Replica & Synchronization Target ✅
Architecture Status ........ FROZEN ✅
