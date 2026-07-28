# Database Schema Extraction — Smart Merchant ERP v1

> **Source of Truth**: Laravel Migrations & Eloquent Models only.
> **Database Engine**: PostgreSQL
> **Generated**: 2026-07-17
> **Purpose**: Official reference for all future offline-first / SQLite phases.

---

# Migration Execution Order

| # | Migration File | Tables Created |
|---|----------------|----------------|
| 1 | `2026_07_11_000000_create_account_types_table.php` | account_types |
| 2 | `2026_07_11_000001_create_core_domain_tables.php` | currencies, accounts, businesses, branches, plans, subscriptions, subscription_payments, roles, permissions, users, user_roles, role_permissions, user_branches |
| 3 | `2026_07_11_000002_create_catalog_and_inventory_domains.php` | categories, brands, units, products, product_units, branch_product_prices, product_images, warehouses, inventories, inventory_transactions, inventory_transaction_lines, inventory_transfers, inventory_transfer_items |
| 4 | `2026_07_11_000003_create_finance_part1_and_purchasing.php` | fiscal_years, fiscal_periods, exchange_rates, chart_of_accounts, payment_terms, payment_methods, cash_registers, cash_transactions, bank_accounts, bank_transactions, suppliers, purchase_invoices, purchase_invoice_items, purchase_returns, purchase_return_items |
| 5 | `2026_07_11_000004_create_sales_domain.php` | customers, channels, sales_invoices, orders, order_items, sales_invoice_items, sales_returns, sales_return_items |
| 6 | `2026_07_11_000005_create_finance_part2_domain.php` | journal_entries, journal_entry_lines, payments, payment_allocations, expense_categories, expenses, opening_balances |
| 7 | `2026_07_11_000006_create_extended_domains.php` | product_channels, carts, cart_items, system_settings, print_settings, sequences, departments, job_titles, employees, employee_documents, taxes, product_taxes, product_variants, stock_adjustments, stock_adjustment_items, attachments, activity_logs, fixed_assets, depreciation_schedules, bank_reconciliations, bank_reconciliation_lines |
| 8 | `2026_07_11_000007_create_business_rule_triggers.php` | *(triggers & functions only — no tables)* |
| 9 | `2026_07_14_000001_create_account_mappings_table.php` | account_mappings |
| 10 | `2026_07_16_000001_create_accounts_receivable_tables.php` | customer_receivables, receivable_entries |
| 11 | `2026_07_16_000002_create_accounts_payable_tables.php` | supplier_payables, payable_entries |
| 12 | `2026_07_16_000003_create_financial_closing_tables.php` | accounting_periods |
| 13 | `2026_07_17_151505_create_personal_access_tokens_table.php` | personal_access_tokens |

---

# DOMAIN 0 — LOOKUP / REFERENCE

---

## Table: `account_types`

**Purpose**: Lookup table for chart of accounts classification (Assets, Liabilities, Equity, Revenue, Expenses).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | bigint (auto-increment) | No | auto | PK — standard integer, NOT UUID |
| name_en | string | No | — | English name |
| name_ar | string | No | — | Arabic name |
| slug | string | No | — | UNIQUE — e.g. assets, liabilities |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (auto-increment bigint)
**Foreign Keys**: None
**Indexes**: unique on `slug`
**Unique Constraints**: `slug`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `AccountType`):
- *No explicit relationships defined in model*

**Migration Source**: `2026_07_11_000000_create_account_types_table.php`
**Model Source**: `App\Domains\Finance\Models\AccountType`

---

# DOMAIN 1 — CORE (Multi-Tenancy & Auth)

---

## Table: `currencies`

**Purpose**: Global currency definitions with exchange rates. Shared across all businesses.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| currency_code | string(10) | No | — | UNIQUE |
| currency_name_ar | string(100) | No | — | |
| currency_name_en | string(100) | No | — | |
| currency_symbol | string(10) | No | — | |
| decimal_places | integer | No | 2 | CHECK: 0–6 |
| exchange_rate | decimal(18,8) | No | 1.00000000 | CHECK: > 0 |
| is_base_currency | boolean | No | false | |
| is_active | boolean | No | true | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: None
**Unique Constraints**: `currency_code`; partial unique index `uq_currencies_single_base` WHERE `is_base_currency = TRUE`
**Check Constraints**: `chk_currencies_decimals` (0–6), `chk_currencies_exchange_rate` (> 0)
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `Currency`):
- hasMany → Plan, Supplier, PurchaseInvoice, PurchaseReturn, Customer, SalesInvoice, Order, SalesReturn, Cart, ChartOfAccount, JournalEntry, Payment, Expense, OpeningBalance, Employee

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\Currency`

---

## Table: `accounts`

**Purpose**: Top-level tenant account (organization). Each account can own multiple businesses.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| name | string(200) | No | — | |
| owner_name | string(150) | No | — | |
| email | string(255) | No | — | UNIQUE |
| phone | string(30) | Yes | — | |
| status | string(20) | No | 'Active' | CHECK: Active, Suspended, Closed |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: None
**Unique Constraints**: `email`
**Check Constraints**: `chk_accounts_status`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Account`):
- hasMany → Business, Subscription, User

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\Account`

---

## Table: `businesses`

**Purpose**: A business entity within an account. Central tenant-isolation node — most tables reference business_id.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| account_id | uuid | No | — | FK → accounts |
| business_name | string(255) | No | — | |
| business_type | string(100) | Yes | — | |
| primary_phone | string(30) | Yes | — | |
| primary_email | string(255) | Yes | — | |
| logo_path | string(500) | Yes | — | |
| status | string(20) | No | 'Active' | CHECK: Active, Inactive |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `account_id` → accounts.id (RESTRICT)
**Unique Constraints**: `(account_id, id)`, `(account_id, business_name)`
**Check Constraints**: `chk_businesses_status`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Business`):
- belongsTo → Account
- hasMany → Branch, Category, Brand, Product, Warehouse, InventoryTransfer, Supplier, PurchaseInvoice, PurchaseReturn, Customer, Channel, SalesInvoice, Order, SalesReturn, Cart, FiscalYear, FiscalPeriod, ChartOfAccount, PaymentTerm, PaymentMethod, JournalEntry, JournalEntryLine, Payment, ExpenseCategory, Expense, OpeningBalance, FixedAsset, BankReconciliation, BankReconciliationLine, Tax, Department, Employee, AttendanceRecord, PayrollSlip, SystemSetting, PrintSetting

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\Business`

---

## Table: `branches`

**Purpose**: Physical or logical branch within a business. Used for location-based operations.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| branch_name | string(255) | No | — | |
| branch_code | string(50) | No | — | |
| phone | string(30) | Yes | — | |
| email | string(255) | Yes | — | |
| address | text | Yes | — | |
| is_default | boolean | No | false | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, branch_code)`; partial unique `uq_branches_single_default` WHERE `is_default = TRUE`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Branch`):
- belongsTo → Business
- hasMany → Warehouse, PurchaseInvoice, PurchaseReturn, SalesInvoice, Order, SalesReturn, Expense, FixedAsset, PrintSetting

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\Branch`

---

## Table: `plans`

**Purpose**: Subscription plans defining pricing and limits for accounts.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| plan_name | string(100) | No | — | UNIQUE |
| currency_id | uuid | No | — | FK → currencies |
| billing_cycle | string(50) | No | — | CHECK: Monthly, Quarterly, SemiAnnual, Yearly |
| duration_months | integer | No | — | CHECK: > 0 |
| price | decimal(18,2) | No | — | CHECK: >= 0 |
| max_businesses | integer | No | 1 | CHECK: > 0 |
| max_branches | integer | No | 1 | CHECK: > 0 |
| max_users | integer | No | 5 | CHECK: > 0 |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `currency_id` → currencies.id (RESTRICT)
**Unique Constraints**: `plan_name`
**Check Constraints**: `chk_plans_billing_cycle`, `chk_plans_price`, `chk_plans_limits`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `Plan`):
- belongsTo → Currency
- hasMany → Subscription

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\Plan`

---

## Table: `subscriptions`

**Purpose**: Active subscription linking an account to a plan.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| account_id | uuid | No | — | FK → accounts |
| plan_id | uuid | No | — | FK → plans |
| start_date | date | No | — | |
| end_date | date | No | — | CHECK: >= start_date |
| amount_paid | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| status | string(20) | No | 'Active' | CHECK: Active, Expired, Cancelled |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `account_id` → accounts.id (RESTRICT), `plan_id` → plans.id (RESTRICT)
**Unique Constraints**: partial unique `uq_subscriptions_active_account` WHERE `status = 'Active'`
**Check Constraints**: `chk_subscriptions_dates`, `chk_subscriptions_amount`, `chk_subscriptions_status`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `Subscription`):
- belongsTo → Account, Plan
- hasMany → SubscriptionPayment

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\Subscription`

---

## Table: `subscription_payments`

**Purpose**: Payment records for subscriptions.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| subscription_id | uuid | No | — | FK → subscriptions |
| account_id | uuid | No | — | FK → accounts |
| currency_id | uuid | No | — | FK → currencies |
| receipt_number | string(50) | No | — | UNIQUE |
| payment_date | timestamp | No | CURRENT_TIMESTAMP | |
| amount | decimal(18,2) | No | — | CHECK: > 0 |
| payment_method | string(100) | Yes | — | |
| reference_number | string(100) | Yes | — | |
| status | string(20) | No | 'Paid' | CHECK: Draft, Paid, Voided |
| notes | text | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `subscription_id` → subscriptions.id (RESTRICT), `account_id` → accounts.id (RESTRICT), `currency_id` → currencies.id (RESTRICT)
**Unique Constraints**: `receipt_number`
**Check Constraints**: `chk_subscription_payments_amount`, `chk_subscription_payments_status`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `SubscriptionPayment`):
- belongsTo → Subscription, Account, Currency

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\SubscriptionPayment`

---

## Table: `roles`

**Purpose**: Business-scoped user roles for RBAC.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| role_name | string(100) | No | — | |
| description | text | Yes | — | |
| is_system_role | boolean | No | false | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, role_name)`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `Role`):
- belongsTo → Business
- belongsToMany → Permission (via role_permissions), User (via user_roles)

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\Role`

---

## Table: `permissions`

**Purpose**: Global permission definitions (not business-scoped).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| module | string(100) | No | — | |
| permission_code | string(100) | No | — | UNIQUE |
| permission_name | string(100) | No | — | |
| description | text | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: None
**Unique Constraints**: `permission_code`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `Permission`):
- belongsToMany → Role (via role_permissions)

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\Permission`

---

## Table: `users`

**Purpose**: System users linked to an account, with branch assignments and role-based access.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| account_id | uuid | No | — | FK → accounts |
| default_branch_id | uuid | Yes | — | Circular FK via user_branches |
| username | string(50) | No | — | |
| email | string(255) | No | — | UNIQUE |
| password_hash | string(255) | No | — | |
| full_name | string(255) | No | — | |
| phone | string(30) | Yes | — | |
| is_active | boolean | No | true | |
| last_login_at | timestamp | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `account_id` → accounts.id (RESTRICT); composite FK `fk_users_default_branch` (id, default_branch_id) → user_branches(user_id, branch_id) (RESTRICT)
**Unique Constraints**: `email`, `(account_id, username)`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `User`):
- belongsTo → Account, Branch (defaultBranch)
- belongsToMany → Branch (via user_branches), Role (via user_roles)
- hasMany → InventoryTransfer, PurchaseInvoice, PurchaseReturn, SalesInvoice, Order, SalesReturn, JournalEntry, Payment, Expense, BankReconciliation (all as created_by)
- hasOne → Employee

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`
**Model Source**: `App\Domains\Core\Models\User`

---

## Table: `user_roles` (Pivot)

**Purpose**: Many-to-many pivot between users and roles.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| user_id | uuid | No | — | FK → users (CASCADE) |
| role_id | uuid | No | — | FK → roles (CASCADE) |
| assigned_at | timestamp | No | CURRENT_TIMESTAMP | |

**Primary Key**: `(user_id, role_id)` — composite
**Foreign Keys**: `user_id` → users.id (CASCADE), `role_id` → roles.id (CASCADE)
**Soft Deletes**: No
**Timestamps**: No
**Model Source**: *No dedicated model — accessed via belongsToMany pivot*

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`

---

## Table: `role_permissions` (Pivot)

**Purpose**: Many-to-many pivot between roles and permissions.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| role_id | uuid | No | — | FK → roles (CASCADE) |
| permission_id | uuid | No | — | FK → permissions (CASCADE) |

**Primary Key**: `(role_id, permission_id)` — composite
**Foreign Keys**: `role_id` → roles.id (CASCADE), `permission_id` → permissions.id (CASCADE)
**Soft Deletes**: No
**Timestamps**: No
**Model Source**: *No dedicated model — accessed via belongsToMany pivot*

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`

---

## Table: `user_branches` (Pivot)

**Purpose**: Many-to-many pivot between users and branches they can access.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| user_id | uuid | No | — | FK → users (CASCADE) |
| branch_id | uuid | No | — | FK → branches (CASCADE) |
| is_active | boolean | No | true | |
| assigned_at | timestamp | No | CURRENT_TIMESTAMP | |

**Primary Key**: `(user_id, branch_id)` — composite
**Foreign Keys**: `user_id` → users.id (CASCADE), `branch_id` → branches.id (CASCADE)
**Unique Constraints**: `uq_user_branches (user_id, branch_id)`
**Soft Deletes**: No
**Timestamps**: No
**Model Source**: *No dedicated model — accessed via belongsToMany pivot*

**Migration Source**: `2026_07_11_000001_create_core_domain_tables.php`

---

---

# DOMAIN 2 — CATALOG

---

## Table: `categories`

**Purpose**: Product categories with self-referencing parent for hierarchical structure, scoped per business.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| parent_id | uuid | Yes | — | Self-referential FK (composite) |
| category_name | string(100) | No | — | |
| category_code | string(50) | Yes | — | |
| description | text | Yes | — | |
| image_path | string(500) | Yes | — | |
| sort_order | integer | No | 0 | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); composite `(business_id, parent_id)` → categories(business_id, id) (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, category_name)`, `(business_id, category_code)`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Category`):
- belongsTo → Category (parent, self-referential)
- hasMany → Category (children), Product

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Catalog\Models\Category`

---

## Table: `brands`

**Purpose**: Product brands scoped per business.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| brand_name | string(100) | No | — | |
| description | text | Yes | — | |
| logo_path | string(500) | Yes | — | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, brand_name)`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `Brand`):
- belongsTo → Business
- hasMany → Product

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Catalog\Models\Brand`

---

## Table: `units`

**Purpose**: Units of measurement (e.g., Piece, Kg, Box) scoped per business.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| unit_name | string(100) | No | — | |
| unit_symbol | string(10) | No | — | |
| unit_description | text | Yes | — | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, unit_name)`, `(business_id, unit_symbol)`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Unit`):
- *Model file is empty (0 bytes) — no relationships defined*

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Catalog\Models\Unit` *(empty file)*

---

## Table: `products`

**Purpose**: Master product definitions with category, brand, and tax linkage.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| category_id | uuid | Yes | — | Composite FK |
| brand_id | uuid | Yes | — | Composite FK |
| tax_id | uuid | Yes | — | No FK constraint in migration |
| product_type | string(50) | No | 'standard' | |
| product_code | string(100) | No | — | |
| product_name | string(255) | No | — | |
| description | text | Yes | — | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); composite `(business_id, category_id)` → categories (RESTRICT); composite `(business_id, brand_id)` → brands (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, product_code)`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Product`):
- belongsTo → Business, Category, Brand, Tax
- hasMany → ProductUnit, ProductImage
- hasOne → ProductUnit (baseUnit, where is_base_unit=true), ProductImage (primaryImage, where is_primary=true)

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Catalog\Models\Product`

---

## Table: `product_units`

**Purpose**: Product-unit combinations with pricing. Each product can have multiple units (e.g., Piece, Box of 12).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| product_id | uuid | No | — | Composite FK |
| unit_id | uuid | No | — | FK → units |
| sku | string(100) | Yes | — | |
| barcode | string(100) | Yes | — | |
| conversion_factor | decimal(18,4) | No | 1.0000 | CHECK: > 0 |
| purchase_price | decimal(18,2) | No | 0.00 | |
| selling_price | decimal(18,2) | No | 0.00 | |
| minimum_price | decimal(18,2) | No | 0.00 | |
| is_base_unit | boolean | No | false | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `unit_id` → units.id (RESTRICT); composite `(business_id, product_id)` → products (CASCADE)
**Unique Constraints**: `(business_id, id)`, `(business_id, barcode)`, `(business_id, sku)`, `(product_id, unit_id)`; partial unique `uq_product_units_one_base` WHERE `is_base_unit = TRUE`
**Check Constraints**: `chk_pu_conversion` (> 0), `chk_pu_prices` (purchase_price >= 0, selling_price >= minimum_price >= 0)
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `ProductUnit`):
- belongsTo → Business, Product, Unit
- hasMany → BranchProductPrice

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Catalog\Models\ProductUnit`

---

## Table: `branch_product_prices`

**Purpose**: Branch-specific price overrides for product units.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| branch_id | uuid | No | — | Composite FK |
| product_unit_id | uuid | No | — | Composite FK |
| purchase_price | decimal(18,2) | No | 0.00 | |
| selling_price | decimal(18,2) | No | 0.00 | |
| minimum_price | decimal(18,2) | No | 0.00 | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, branch_id)` → branches (CASCADE); composite `(business_id, product_unit_id)` → product_units (CASCADE)
**Unique Constraints**: `(branch_id, product_unit_id)`
**Check Constraints**: `chk_bpp_prices` (purchase_price >= 0, selling_price >= minimum_price >= 0)
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `BranchProductPrice`):
- belongsTo → Branch, ProductUnit

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Catalog\Models\BranchProductPrice`

---

## Table: `product_images`

**Purpose**: Product image gallery with primary image designation.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| product_id | uuid | No | — | FK → products (CASCADE) |
| image_path | string(500) | No | — | |
| is_primary | boolean | No | false | |
| created_at | timestamp | No | CURRENT_TIMESTAMP | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `product_id` → products.id (CASCADE)
**Unique Constraints**: partial unique `uq_product_images_primary` WHERE `is_primary = TRUE`
**Soft Deletes**: No
**Timestamps**: Only `created_at`

**Relationships** (from Model `ProductImage`):
- belongsTo → Product

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Catalog\Models\ProductImage`

---

# DOMAIN 3 — INVENTORY

---

## Table: `warehouses`

**Purpose**: Storage locations linked to a branch. Each branch can have a default warehouse.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| branch_id | uuid | No | — | Composite FK |
| warehouse_name | string(255) | No | — | |
| warehouse_code | string(100) | No | — | |
| address | string(255) | Yes | — | |
| is_default | boolean | No | false | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); composite `(business_id, branch_id)` → branches (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, warehouse_code)`; partial unique `uq_warehouses_default_branch` (business_id, branch_id) WHERE `is_default = TRUE`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Warehouse`):
- belongsTo → Business, Branch
- hasMany → Inventory, InventoryTransaction, InventoryTransfer (from/to), PurchaseInvoice, PurchaseInvoiceItem, PurchaseReturnItem, SalesInvoiceItem, SalesReturnItem

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Inventory\Models\Warehouse`

---

## Table: `inventories`

**Purpose**: Current stock levels per warehouse per product_unit. Single source of truth for on-hand quantity.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| warehouse_id | uuid | No | — | FK → warehouses |
| product_unit_id | uuid | No | — | FK → product_units |
| quantity | decimal(18,3) | No | 0.000 | CHECK: >= 0 |
| average_cost | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| alert_quantity | decimal(18,3) | No | 0.000 | CHECK: >= 0 |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT), `warehouse_id` → warehouses.id (RESTRICT), `product_unit_id` → product_units.id (RESTRICT)
**Unique Constraints**: `(business_id, warehouse_id, product_unit_id)`
**Check Constraints**: `chk_inventories_values` (quantity >= 0, average_cost >= 0, alert_quantity >= 0)
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Inventory`):
- belongsTo → Business, Warehouse, ProductUnit

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Inventory\Models\Inventory`

---

## Table: `inventory_transactions`

**Purpose**: Header record for inventory movements (receipts, dispatches, adjustments, opening balances).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| branch_id | uuid | No | — | Composite FK |
| warehouse_id | uuid | No | — | Composite FK |
| transaction_type | string(20) | No | — | CHECK: Receipt, Dispatch, Adjustment In, Adjustment Out, Opening Balance |
| movement_direction | string(3) | No | — | CHECK: IN, OUT |
| status | string(20) | No | 'Draft' | CHECK: Draft, Posted, Reversed |
| reference_type | string(50) | Yes | — | CHECK: SalesInvoice, SalesReturn, PurchaseInvoice, PurchaseReturn, Transfer, Adjustment or NULL |
| reference_id | uuid | Yes | — | Polymorphic reference |
| transaction_date | timestamp | No | CURRENT_TIMESTAMP | |
| created_by | uuid | No | — | FK → users |
| posted_by | uuid | Yes | — | FK → users |
| posted_at | timestamp | Yes | — | |
| reversed_by | uuid | Yes | — | FK → users |
| reversed_at | timestamp | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, branch_id)` → branches (RESTRICT); composite `(business_id, warehouse_id)` → warehouses (RESTRICT); `created_by` → users.id (RESTRICT); `posted_by` → users.id (RESTRICT); `reversed_by` → users.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Indexes**: `idx_inv_tx_reference` on (reference_type, reference_id)
**Check Constraints**: `chk_inv_tx_status`, `chk_inv_tx_type`, `chk_inv_tx_movement`, `chk_inv_tx_ref`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `InventoryTransaction`):
- belongsTo → Business, Branch, Warehouse, User (creator, poster, reverser)
- hasMany → InventoryTransactionLine

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Inventory\Models\InventoryTransaction`

---

## Table: `inventory_transaction_lines`

**Purpose**: Line items for inventory transactions specifying product, quantity, and cost.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| inventory_transaction_id | uuid | No | — | Composite FK |
| product_unit_id | uuid | No | — | Composite FK |
| line_number | integer | No | 1 | |
| quantity | decimal(18,3) | No | — | CHECK: > 0 |
| unit_cost | decimal(18,2) | No | 0.00 | CHECK: >= 0 |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, inventory_transaction_id)` → inventory_transactions (CASCADE); composite `(business_id, product_unit_id)` → product_units (RESTRICT)
**Check Constraints**: `chk_inv_tx_line_qty` (> 0), `chk_inv_tx_line_cost` (>= 0)
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `InventoryTransactionLine`):
- belongsTo → Business, InventoryTransaction, ProductUnit

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Inventory\Models\InventoryTransactionLine`

---

## Table: `inventory_transfers`

**Purpose**: Header for stock transfer between warehouses within the same business.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| from_warehouse_id | uuid | No | — | Composite FK |
| to_warehouse_id | uuid | No | — | Composite FK |
| transfer_number | string(50) | No | — | |
| transfer_date | timestamp | No | CURRENT_TIMESTAMP | |
| status | string(20) | No | 'Pending' | CHECK: Pending, Completed, Cancelled |
| notes | text | Yes | — | |
| created_by | uuid | No | — | FK → users |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); composite `(business_id, from_warehouse_id)` → warehouses (RESTRICT); composite `(business_id, to_warehouse_id)` → warehouses (RESTRICT); `created_by` → users.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, transfer_number)`
**Check Constraints**: `chk_inv_transfers_status`, `chk_inv_transfers_wh` (from ≠ to)
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `InventoryTransfer`):
- belongsTo → Business, Warehouse (from), Warehouse (to), User (createdBy)
- hasMany → InventoryTransferItem

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Inventory\Models\InventoryTransfer`

---

## Table: `inventory_transfer_items`

**Purpose**: Line items for inventory transfers specifying product, quantity, and cost.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| transfer_id | uuid | No | — | Composite FK |
| product_unit_id | uuid | No | — | Composite FK |
| quantity | decimal(18,3) | No | — | CHECK: > 0 |
| unit_cost | decimal(18,2) | No | 0.00 | CHECK: >= 0 |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, transfer_id)` → inventory_transfers (CASCADE); composite `(business_id, product_unit_id)` → product_units (RESTRICT)
**Unique Constraints**: `(transfer_id, product_unit_id)`
**Check Constraints**: `chk_inv_ti_values` (quantity > 0, unit_cost >= 0)
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `InventoryTransferItem`):
- belongsTo → Business, InventoryTransfer, ProductUnit

**Migration Source**: `2026_07_11_000002_create_catalog_and_inventory_domains.php`
**Model Source**: `App\Domains\Inventory\Models\InventoryTransferItem`

---

---

# DOMAIN 4 — FINANCE (Part 1: Structure & Cash/Bank)

---

## Table: `fiscal_years`

**Purpose**: Accounting fiscal year definitions per business.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| fiscal_year_code | string(20) | No | — | |
| fiscal_year_name | string(100) | No | — | |
| description | text | Yes | — | |
| start_date | date | No | — | |
| end_date | date | No | — | CHECK: > start_date |
| status | string(20) | No | 'Open' | CHECK: Open, Closed |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, fiscal_year_code)`
**Check Constraints**: `chk_fy_status`, `chk_fy_dates`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `FiscalYear`):
- belongsTo → Business
- hasMany → FiscalPeriod (periods), JournalEntry, OpeningBalance

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\FiscalYear`

---

## Table: `fiscal_periods`

**Purpose**: Monthly periods within a fiscal year (1–12).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| fiscal_year_id | uuid | No | — | Composite FK |
| period_number | integer | No | — | CHECK: 1–12 |
| period_name | string(100) | No | — | |
| start_date | date | No | — | |
| end_date | date | No | — | CHECK: > start_date |
| status | string(20) | No | 'Open' | CHECK: Open, Closed |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, fiscal_year_id)` → fiscal_years (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(fiscal_year_id, period_number)`
**Check Constraints**: `chk_fp_status`, `chk_fp_period` (1–12), `chk_fp_dates`
**Triggers**: `trg_fiscal_period_overlap` — prevents overlapping dates within same fiscal year
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `FiscalPeriod`):
- belongsTo → Business, FiscalYear
- hasMany → JournalEntry

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\FiscalPeriod`

---

## Table: `exchange_rates`

**Purpose**: Historical exchange rates between currencies per business.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| source_currency_id | uuid | No | — | FK → currencies |
| target_currency_id | uuid | No | — | FK → currencies |
| effective_date | date | No | — | |
| rate | decimal(20,8) | No | — | CHECK: > 0 |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT), `source_currency_id` → currencies.id (RESTRICT), `target_currency_id` → currencies.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, source_currency_id, target_currency_id, effective_date)` as `uq_exchange_rates_date`
**Check Constraints**: `chk_er_diff_currencies` (source ≠ target), `chk_er_rate_positive`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `ExchangeRate`):
- belongsTo → Business, Currency (source), Currency (target)

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\ExchangeRate`

---

## Table: `chart_of_accounts`

**Purpose**: Full chart of accounts with hierarchical parent-child structure. Core of the accounting system.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| parent_account_id | uuid | Yes | — | Self-referential composite FK |
| currency_id | uuid | Yes | — | FK → currencies |
| account_code | string(50) | No | — | |
| account_name | string(255) | No | — | |
| description | text | Yes | — | |
| account_type_id | bigint | No | — | FK → account_types |
| account_category | string(100) | Yes | — | |
| normal_balance | string(10) | No | — | CHECK: Debit, Credit |
| account_level | integer | No | 1 | CHECK: > 0 |
| allow_posting | boolean | No | false | |
| is_system | boolean | No | false | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `account_type_id` → account_types.id (RESTRICT); composite `(business_id, parent_account_id)` → chart_of_accounts (self, RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, account_code)`
**Check Constraints**: `chk_coa_balance`, `chk_coa_level`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `ChartOfAccount`):
- belongsTo → Business, AccountType, ChartOfAccount (parent), Currency
- hasMany → ChartOfAccount (children), JournalEntryLine, PaymentMethod, Payment, ExpenseCategory, OpeningBalance, BankReconciliation, Customer (receivableAccount), Supplier (payableAccount)

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\ChartOfAccount`

---

## Table: `payment_terms`

**Purpose**: Payment term definitions (e.g., Net 30, Net 60) for customers and suppliers.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| term_name | string(100) | No | — | |
| days_to_due | integer | No | 0 | CHECK: >= 0 |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE)
**Unique Constraints**: `(business_id, id)`, `(business_id, term_name)`
**Check Constraints**: `chk_pt_days`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `PaymentTerm`):
- belongsTo → Business

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\PaymentTerm`

---

## Table: `payment_methods`

**Purpose**: Payment method definitions linked to a chart of account.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| chart_of_account_id | uuid | No | — | Composite FK |
| method_code | string(30) | No | — | |
| method_name | string(100) | No | — | |
| payment_type | string(20) | No | — | CHECK: Cash, Bank, Card, DigitalWallet, Other |
| is_active | boolean | No | true | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); composite `(business_id, chart_of_account_id)` → chart_of_accounts (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, method_code)`
**Check Constraints**: `chk_pm_type`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `PaymentMethod`):
- belongsTo → Business, ChartOfAccount
- hasMany → Payment, Expense

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\PaymentMethod`

---

## Table: `cash_registers`

**Purpose**: Physical or logical cash registers per branch for POS operations.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| branch_id | uuid | No | — | Composite FK |
| currency_id | uuid | No | — | FK → currencies |
| register_name | string(100) | No | — | |
| status | string(20) | No | 'Closed' | CHECK: Open, Closed |
| current_balance | decimal(15,4) | No | 0 | |
| created_by | uuid | Yes | — | FK → users (NULL ON DELETE) |
| updated_by | uuid | Yes | — | FK → users (NULL ON DELETE) |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); `currency_id` → currencies.id (RESTRICT); composite `(business_id, branch_id)` → branches (RESTRICT); `created_by` → users.id (NULL); `updated_by` → users.id (NULL)
**Unique Constraints**: `(business_id, id)`, `(business_id, register_name)`
**Check Constraints**: `chk_cr_status`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `CashRegister`):
- belongsTo → Business, Branch, Currency, User (creator), User (updater)
- hasMany → CashTransaction

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\CashRegister`

---

## Table: `cash_transactions`

**Purpose**: Individual cash movement records within a register.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| cash_register_id | uuid | No | — | FK → cash_registers (CASCADE) |
| transaction_type | string(30) | No | — | CHECK: Deposit, Withdrawal, Transfer In/Out, Adjustment, Payment, Receipt |
| amount | decimal(15,4) | No | — | CHECK: > 0 |
| document_type | string(100) | Yes | — | Polymorphic |
| document_id | uuid | Yes | — | Polymorphic |
| notes | text | Yes | — | |
| reference_id | uuid | Yes | — | Self-referential FK (NULL ON DELETE) |
| created_by | uuid | Yes | — | FK → users (NULL ON DELETE) |
| created_at | timestamp | No | CURRENT_TIMESTAMP | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); `cash_register_id` → cash_registers.id (CASCADE); `reference_id` → cash_transactions.id (self, NULL ON DELETE); `created_by` → users.id (NULL)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_ct_type`, `chk_ct_amount`
**Soft Deletes**: No
**Timestamps**: Only `created_at`

**Relationships** (from Model `CashTransaction`):
- belongsTo → Business, CashRegister, CashTransaction (reference, self), User (creator)
- morphTo → financialDocument (document_type, document_id)

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\CashTransaction`

---

## Table: `bank_accounts`

**Purpose**: Business bank accounts with balances and reconciliation tracking.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| branch_id | uuid | Yes | — | Composite FK |
| currency_id | uuid | No | — | FK → currencies |
| account_number | string(50) | No | — | |
| iban | string(50) | Yes | — | |
| bank_name | string(100) | No | — | |
| display_name | string(100) | Yes | — | |
| description | text | Yes | — | |
| status | string(20) | No | 'Active' | CHECK: Active, Frozen, Closed |
| is_default | boolean | No | false | |
| opening_balance | decimal(18,4) | No | 0.0000 | |
| opening_balance_date | date | Yes | — | |
| current_balance | decimal(18,4) | No | 0.0000 | |
| last_reconciled_balance | decimal(18,4) | Yes | — | |
| last_reconciled_at | timestamp | Yes | — | |
| created_by | uuid | Yes | — | FK → users (NULL) |
| updated_by | uuid | Yes | — | FK → users (NULL) |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); `currency_id` → currencies.id (RESTRICT); composite `(business_id, branch_id)` → branches (RESTRICT); `created_by` → users.id (NULL); `updated_by` → users.id (NULL)
**Unique Constraints**: `(business_id, id)`, `(business_id, account_number)`, `(business_id, iban)`
**Check Constraints**: `chk_ba_status`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `BankAccount`):
- belongsTo → Business, Branch, Currency, User (creator), User (updater)
- hasMany → BankTransaction

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\BankAccount`

---

## Table: `bank_transactions`

**Purpose**: Individual bank transaction records with multi-currency support.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| bank_account_id | uuid | No | — | Composite FK |
| transaction_type | string(50) | No | — | CHECK: Deposit, Withdrawal, Transfer In/Out, Adjustment, Bank Fee, Interest, Opening Balance |
| direction | string(10) | No | — | CHECK: Credit, Debit |
| amount | decimal(18,4) | No | — | CHECK: > 0 |
| foreign_currency_amount | decimal(18,4) | Yes | — | |
| foreign_currency_code | string(3) | Yes | — | |
| exchange_rate | decimal(18,6) | Yes | — | |
| document_type | string | Yes | — | Polymorphic |
| document_id | uuid | Yes | — | Polymorphic |
| bank_transfer_id | uuid | Yes | — | |
| reconciliation_status | string(30) | No | 'Unreconciled' | |
| notes | text | Yes | — | |
| created_by | uuid | Yes | — | FK → users (NULL) |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); composite `(business_id, bank_account_id)` → bank_accounts (CASCADE); `created_by` → users.id (NULL)
**Unique Constraints**: `(business_id, id)`
**Indexes**: `(document_type, document_id)`
**Check Constraints**: `chk_bt_type`, `chk_bt_direction`, `chk_bt_amount`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `BankTransaction`):
- belongsTo → BankAccount, Business, User (creator)
- morphTo → financialDocument (document_type, document_id)

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Finance\Models\BankTransaction`

---

---

# DOMAIN 5 — PURCHASING

---

## Table: `suppliers`

**Purpose**: Supplier master data with credit terms, opening balances, and linked accounting accounts.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| supplier_name | string(255) | No | — | |
| contact_person | string(255) | Yes | — | |
| phone | string(30) | Yes | — | |
| supplier_address | string(255) | Yes | — | |
| default_currency_id | uuid | Yes | — | FK → currencies (NULL ON DELETE) |
| payment_term_id | uuid | Yes | — | Composite FK |
| payable_account_id | uuid | Yes | — | Composite FK → chart_of_accounts |
| credit_limit | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| opening_balance | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| opening_balance_type | string(10) | Yes | — | CHECK: debit, credit |
| opening_balance_date | date | Yes | — | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `default_currency_id` → currencies.id (NULL); composite `(business_id, payment_term_id)` → payment_terms (RESTRICT); composite `(business_id, payable_account_id)` → chart_of_accounts (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_sup_credit`, `chk_sup_balance`, `chk_sup_bal_type`, `chk_sup_bal_req` (balance > 0 requires type)
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Supplier`):
- belongsTo → Business, Currency (defaultCurrency), PaymentTerm, ChartOfAccount (payableAccount)
- hasMany → PurchaseInvoice

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Purchasing\Models\Supplier`

---

## Table: `purchase_invoices`

**Purpose**: Purchase invoice headers with multi-currency support, dual totals (foreign + base), and audit trail.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| branch_id | uuid | No | — | Composite FK |
| supplier_id | uuid | No | — | Composite FK |
| warehouse_id | uuid | No | — | Composite FK |
| invoice_number | string(50) | No | — | |
| purchase_date | timestamp | No | CURRENT_TIMESTAMP | |
| due_date | timestamp | Yes | — | CHECK: >= purchase_date |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| sub_total | decimal(18,2) | No | 0.00 | |
| discount_total | decimal(18,2) | No | 0.00 | |
| tax_total | decimal(18,2) | No | 0.00 | |
| grand_total | decimal(18,2) | No | 0.00 | |
| base_sub_total | decimal(18,2) | No | 0.00 | |
| base_discount_total | decimal(18,2) | No | 0.00 | |
| base_tax_total | decimal(18,2) | No | 0.00 | |
| base_grand_total | decimal(18,2) | No | 0.00 | |
| payment_status | string(20) | No | 'Unpaid' | CHECK: Unpaid, Partial, Paid |
| status | string(20) | No | 'Draft' | CHECK: Draft, Posted, Reversed |
| notes | text | Yes | — | |
| created_by | uuid | No | — | FK → users |
| posted_by | uuid | Yes | — | FK → users |
| posted_at | timestamp | Yes | — | |
| reversed_by | uuid | Yes | — | FK → users |
| reversed_at | timestamp | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (RESTRICT); `posted_by` → users.id (RESTRICT); `reversed_by` → users.id (RESTRICT); composite `(business_id, branch_id)` → branches; composite `(business_id, supplier_id)` → suppliers; composite `(business_id, warehouse_id)` → warehouses
**Unique Constraints**: `(business_id, id)`, `(business_id, invoice_number)`
**Check Constraints**: `chk_pi_payment`, `chk_pi_status`, `chk_pi_dates`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `PurchaseInvoice`):
- belongsTo → Business, Branch, Supplier, Warehouse, Currency, User (createdBy, postedBy, reversedBy)
- hasMany → PurchaseInvoiceItem (items), PurchaseReturn (returns)

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Purchasing\Models\PurchaseInvoice`

---

## Table: `purchase_invoice_items`

**Purpose**: Line items for purchase invoices.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| purchase_invoice_id | uuid | No | — | Composite FK |
| product_unit_id | uuid | No | — | Composite FK |
| warehouse_id | uuid | No | — | Composite FK |
| tax_id | uuid | Yes | — | No FK constraint (commented out) |
| quantity | decimal(18,3) | No | — | CHECK: > 0 |
| unit_price | decimal(18,2) | No | — | CHECK: >= 0 |
| discount | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| tax | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| line_total | decimal(18,2) | No | — | CHECK: >= 0 |
| base_line_total | decimal(18,2) | No | 0.00 | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, purchase_invoice_id)` → purchase_invoices (CASCADE); composite `(business_id, product_unit_id)` → product_units (RESTRICT); composite `(business_id, warehouse_id)` → warehouses (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_pi_item_quantity`, `chk_pi_item_price`, `chk_pi_item_discount`, `chk_pi_item_tax`, `chk_pi_item_total`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `PurchaseInvoiceItem`):
- belongsTo → Business, PurchaseInvoice, ProductUnit, Warehouse, Tax
- hasMany → PurchaseReturnItem (returnedItems)

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Purchasing\Models\PurchaseInvoiceItem`

---

## Table: `purchase_returns`

**Purpose**: Purchase return headers linked to a purchase invoice.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| branch_id | uuid | No | — | Composite FK |
| purchase_invoice_id | uuid | No | — | Composite FK |
| return_number | string(50) | No | — | |
| return_date | timestamp | No | CURRENT_TIMESTAMP | |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| total_amount | decimal(18,2) | No | 0.00 | |
| base_total_amount | decimal(18,2) | No | 0.00 | |
| status | string(20) | No | 'Draft' | |
| notes | text | Yes | — | |
| created_by | uuid | No | — | FK → users |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (RESTRICT); composite `(business_id, branch_id)` → branches; composite `(business_id, purchase_invoice_id)` → purchase_invoices
**Unique Constraints**: `(business_id, id)`, `(business_id, return_number)`
**Triggers**: `trg_purchase_return_qty` — validates returned quantity does not exceed purchased quantity
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `PurchaseReturn`):
- belongsTo → Business, Branch, PurchaseInvoice, Currency, User (createdBy)
- hasMany → PurchaseReturnItem (items)

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Purchasing\Models\PurchaseReturn`

---

## Table: `purchase_return_items`

**Purpose**: Line items for purchase returns, linked to original purchase invoice items.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| purchase_return_id | uuid | No | — | Composite FK |
| purchase_invoice_item_id | uuid | No | — | FK → purchase_invoice_items |
| warehouse_id | uuid | No | — | Composite FK |
| quantity | decimal(18,3) | No | — | |
| unit_price | decimal(18,2) | No | — | |
| line_total | decimal(18,2) | No | — | |
| base_line_total | decimal(18,2) | No | 0.00 | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, purchase_return_id)` → purchase_returns (CASCADE); `purchase_invoice_item_id` → purchase_invoice_items.id (RESTRICT); composite `(business_id, warehouse_id)` → warehouses (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `PurchaseReturnItem`):
- belongsTo → Business, PurchaseReturn, PurchaseInvoiceItem, Warehouse

**Migration Source**: `2026_07_11_000003_create_finance_part1_and_purchasing.php`
**Model Source**: `App\Domains\Purchasing\Models\PurchaseReturnItem`

---

# DOMAIN 6 — SALES

---

## Table: `customers`

**Purpose**: Customer master data with credit terms, opening balances, and linked accounting accounts.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| customer_name | string(255) | No | — | |
| phone | string(30) | Yes | — | |
| email | string(255) | Yes | — | |
| address | text | Yes | — | |
| credit_limit | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| default_currency_id | uuid | Yes | — | FK → currencies (NULL ON DELETE) |
| payment_term_id | uuid | Yes | — | Composite FK |
| receivable_account_id | uuid | Yes | — | Composite FK → chart_of_accounts |
| opening_balance | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| opening_balance_type | string(10) | Yes | — | CHECK: debit, credit |
| opening_balance_date | date | Yes | — | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `default_currency_id` → currencies.id (NULL); composite `(business_id, payment_term_id)` → payment_terms (RESTRICT); composite `(business_id, receivable_account_id)` → chart_of_accounts (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_cust_credit`, `chk_cust_balance`, `chk_cust_bal_type`, `chk_cust_bal_req`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Customer`):
- belongsTo → Business, Currency (defaultCurrency), PaymentTerm, ChartOfAccount (receivableAccount)
- hasMany → SalesInvoice, Order, Cart

**Migration Source**: `2026_07_11_000004_create_sales_domain.php`
**Model Source**: `App\Domains\Sales\Models\Customer`

---

## Table: `channels`

**Purpose**: Sales channel definitions (POS, Ecommerce, B2B, etc.).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| channel_name | string(100) | No | — | |
| channel_code | string(50) | No | — | |
| channel_type | string(50) | No | — | CHECK: POS, Ecommerce, B2B, Marketplace, Other |
| is_active | boolean | No | true | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE)
**Unique Constraints**: `(business_id, id)`, `(business_id, channel_code)`
**Check Constraints**: `chk_chan_type`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `Channel`):
- belongsTo → Business
- hasMany → Order, Cart
- belongsToMany → ProductUnit (via product_channels)

**Migration Source**: `2026_07_11_000004_create_sales_domain.php`
**Model Source**: `App\Domains\Sales\Models\Channel`

---

## Table: `sales_invoices`

**Purpose**: Sales invoice headers with multi-currency support and dual totals.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| branch_id | uuid | No | — | Composite FK |
| customer_id | uuid | Yes | — | Composite FK (null for walk-in) |
| invoice_number | string(50) | No | — | |
| invoice_date | timestamp | No | CURRENT_TIMESTAMP | |
| due_date | timestamp | Yes | — | |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| sub_total | decimal(18,2) | No | 0.00 | |
| discount_total | decimal(18,2) | No | 0.00 | |
| tax_total | decimal(18,2) | No | 0.00 | |
| grand_total | decimal(18,2) | No | 0.00 | |
| base_sub_total | decimal(18,2) | No | 0.00 | |
| base_discount_total | decimal(18,2) | No | 0.00 | |
| base_tax_total | decimal(18,2) | No | 0.00 | |
| base_grand_total | decimal(18,2) | No | 0.00 | |
| payment_status | string(20) | No | 'Unpaid' | CHECK: Unpaid, Partial, Paid |
| status | string(20) | No | 'Draft' | CHECK: Draft, Posted, Reversed |
| notes | text | Yes | — | |
| created_by | uuid | No | — | FK → users |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (RESTRICT); composite `(business_id, branch_id)` → branches; composite `(business_id, customer_id)` → customers
**Unique Constraints**: `(business_id, id)`, `(business_id, invoice_number)`
**Indexes**: `idx_sales_invoices_status` on (status, payment_status)
**Check Constraints**: `chk_si_payment`, `chk_si_status`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `SalesInvoice`):
- belongsTo → Business, Branch, Customer, Currency, User (createdBy)
- hasMany → SalesInvoiceItem (items), SalesReturn (returns)

**Migration Source**: `2026_07_11_000004_create_sales_domain.php`
**Model Source**: `App\Domains\Sales\Models\SalesInvoice`

---

## Table: `orders`

**Purpose**: Sales orders from channels, optionally linked to a customer.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| branch_id | uuid | No | — | Composite FK |
| channel_id | uuid | No | — | Composite FK |
| customer_id | uuid | Yes | — | Composite FK |
| order_number | string(50) | No | — | |
| order_date | timestamp | No | CURRENT_TIMESTAMP | |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| sub_total | decimal(18,2) | No | 0.00 | |
| discount_total | decimal(18,2) | No | 0.00 | |
| tax_total | decimal(18,2) | No | 0.00 | |
| grand_total | decimal(18,2) | No | 0.00 | |
| base_sub_total | decimal(18,2) | No | 0.00 | |
| base_discount_total | decimal(18,2) | No | 0.00 | |
| base_tax_total | decimal(18,2) | No | 0.00 | |
| base_grand_total | decimal(18,2) | No | 0.00 | |
| payment_status | string(20) | No | 'Unpaid' | |
| status | string(30) | No | 'Pending' | |
| notes | text | Yes | — | |
| created_by | uuid | Yes | — | FK → users (NULL ON DELETE) |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (NULL); composite `(business_id, branch_id)` → branches; composite `(business_id, channel_id)` → channels; `customer_id` → No FK constraint in PostgreSQL migration (Customer owned by SQLite ERP)
**Unique Constraints**: `(business_id, id)`, `(business_id, order_number)`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Order`):
- belongsTo → Business, Branch, Channel, Customer, Currency, User (createdBy)
- hasMany → OrderItem (items)

**Migration Source**: `2026_07_11_000004_create_sales_domain.php`
**Model Source**: `App\Domains\Sales\Models\Order`

---

## Table: `order_items`

**Purpose**: Line items for sales orders.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| order_id | uuid | No | — | Composite FK |
| product_unit_id | uuid | No | — | Composite FK |
| quantity | decimal(18,3) | No | — | |
| unit_price | decimal(18,2) | No | — | |
| discount | decimal(18,2) | No | 0.00 | |
| tax | decimal(18,2) | No | 0.00 | |
| line_total | decimal(18,2) | No | — | |
| base_line_total | decimal(18,2) | No | 0.00 | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, order_id)` → orders (CASCADE); composite `(business_id, product_unit_id)` → product_units (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `OrderItem`):
- belongsTo → Business, Order, ProductUnit
- hasMany → SalesInvoiceItem

**Migration Source**: `2026_07_11_000004_create_sales_domain.php`
**Model Source**: `App\Domains\Sales\Models\OrderItem`

---

## Table: `sales_invoice_items`

**Purpose**: Line items for sales invoices with cost tracking and optional order item linkage.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| sales_invoice_id | uuid | No | — | Composite FK |
| order_item_id | uuid | Yes | — | FK → order_items (NULL ON DELETE) |
| product_unit_id | uuid | No | — | Composite FK |
| warehouse_id | uuid | No | — | Composite FK |
| tax_id | uuid | Yes | — | No FK constraint (commented out) |
| quantity | decimal(18,3) | No | — | CHECK: > 0 |
| unit_price | decimal(18,2) | No | — | CHECK: >= 0 |
| cost_price | decimal(18,2) | No | 0.00 | |
| discount | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| tax | decimal(18,2) | No | 0.00 | |
| line_total | decimal(18,2) | No | — | |
| cost_total | decimal(18,2) | No | 0.00 | |
| base_line_total | decimal(18,2) | No | 0.00 | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, sales_invoice_id)` → sales_invoices (CASCADE); `order_item_id` → order_items.id (NULL); composite `(business_id, product_unit_id)` → product_units (RESTRICT); composite `(business_id, warehouse_id)` → warehouses (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_sii_quantity`, `chk_sii_price`, `chk_sii_discount`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `SalesInvoiceItem`):
- belongsTo → Business, SalesInvoice, OrderItem, ProductUnit, Warehouse, Tax
- hasMany → SalesReturnItem (returnedItems)

**Migration Source**: `2026_07_11_000004_create_sales_domain.php`
**Model Source**: `App\Domains\Sales\Models\SalesInvoiceItem`

---

## Table: `sales_returns`

**Purpose**: Sales return headers linked to a sales invoice.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| branch_id | uuid | No | — | Composite FK |
| sales_invoice_id | uuid | No | — | Composite FK |
| return_number | string(50) | No | — | |
| return_date | timestamp | No | CURRENT_TIMESTAMP | |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| total_amount | decimal(18,2) | No | 0.00 | |
| base_total_amount | decimal(18,2) | No | 0.00 | |
| status | string(20) | No | 'Draft' | |
| notes | text | Yes | — | |
| created_by | uuid | No | — | FK → users |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (RESTRICT); composite `(business_id, branch_id)` → branches; composite `(business_id, sales_invoice_id)` → sales_invoices
**Unique Constraints**: `(business_id, id)`, `(business_id, return_number)`
**Triggers**: `trg_sales_return_qty` — validates returned quantity does not exceed invoiced quantity
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `SalesReturn`):
- belongsTo → Business, Branch, SalesInvoice, Currency, User (createdBy)
- hasMany → SalesReturnItem (items)

**Migration Source**: `2026_07_11_000004_create_sales_domain.php`
**Model Source**: `App\Domains\Sales\Models\SalesReturn`

---

## Table: `sales_return_items`

**Purpose**: Line items for sales returns, linked to original sales invoice items.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| sales_return_id | uuid | No | — | Composite FK |
| sales_invoice_item_id | uuid | No | — | FK → sales_invoice_items |
| warehouse_id | uuid | No | — | Composite FK |
| quantity | decimal(18,3) | No | — | |
| unit_price | decimal(18,2) | No | — | |
| cost_price | decimal(18,2) | No | 0.00 | |
| total_price | decimal(18,2) | No | — | |
| cost_total | decimal(18,2) | No | 0.00 | |
| base_total_price | decimal(18,2) | No | 0.00 | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, sales_return_id)` → sales_returns (CASCADE); `sales_invoice_item_id` → sales_invoice_items.id (RESTRICT); composite `(business_id, warehouse_id)` → warehouses (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `SalesReturnItem`):
- belongsTo → Business, SalesReturn, SalesInvoiceItem, Warehouse

**Migration Source**: `2026_07_11_000004_create_sales_domain.php`
**Model Source**: `App\Domains\Sales\Models\SalesReturnItem`

---

---

# DOMAIN 7 — FINANCE (Part 2: Journals, Payments, Expenses)

---

## Table: `journal_entries`

**Purpose**: General ledger journal entry headers. All financial postings flow through this table.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| fiscal_year_id | uuid | No | — | Composite FK |
| fiscal_period_id | uuid | No | — | |
| journal_number | string(50) | No | — | |
| document_date | date | No | — | |
| posting_date | date | Yes | — | |
| journal_type | string(50) | No | — | CHECK: Manual, SalesInvoice, PurchaseInvoice, Payment, InventoryAdjustment, Reverse |
| document_type | string(50) | No | — | CHECK: same as journal_type |
| document_id | uuid | Yes | — | Polymorphic reference |
| document_number | string(50) | Yes | — | |
| original_journal_id | uuid | Yes | — | Self-referential FK |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| description | text | Yes | — | |
| status | string(20) | No | 'Draft' | CHECK: Draft, Posted, Reversed |
| created_by | uuid | No | — | FK → users |
| posted_by | uuid | Yes | — | FK → users |
| reversed_by | uuid | Yes | — | FK → users |
| posted_at | timestamp | Yes | — | |
| reversed_at | timestamp | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (RESTRICT); `posted_by` → users.id (RESTRICT); `reversed_by` → users.id (RESTRICT); `original_journal_id` → journal_entries.id (self, RESTRICT); composite `(business_id, fiscal_year_id)` → fiscal_years
**Unique Constraints**: `(business_id, id)`, `(business_id, journal_number)`
**Indexes**: `idx_je_document` on (document_type, document_id)
**Check Constraints**: `chk_je_jnl_type`, `chk_je_doc_type`, `chk_je_status`
**Triggers**: `trg_journal_balance_check` — prevents posting unless base debits = base credits
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `JournalEntry`):
- belongsTo → Business, FiscalYear, FiscalPeriod, Currency, User (creator, poster, reverser), JournalEntry (originalJournal, self)
- hasMany → JournalEntryLine (lines)

**Migration Source**: `2026_07_11_000005_create_finance_part2_domain.php`
**Model Source**: `App\Domains\Finance\Models\JournalEntry`

---

## Table: `journal_entry_lines`

**Purpose**: Individual debit/credit lines within a journal entry.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| journal_entry_id | uuid | No | — | Composite FK |
| line_number | integer | No | — | |
| chart_of_account_id | uuid | No | — | Composite FK |
| description | text | Yes | — | |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| type | string(10) | No | — | CHECK: Debit, Credit |
| foreign_amount | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| base_amount | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| document_type | string(50) | Yes | — | Polymorphic |
| document_id | uuid | Yes | — | Polymorphic |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, journal_entry_id)` → journal_entries (CASCADE); composite `(business_id, chart_of_account_id)` → chart_of_accounts (RESTRICT); `currency_id` → currencies.id (RESTRICT)
**Unique Constraints**: `(journal_entry_id, line_number)`
**Check Constraints**: `chk_jel_type`, `chk_jel_amount`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `JournalEntryLine`):
- belongsTo → JournalEntry, ChartOfAccount, Currency
- morphTo → financialDocument (document_type, document_id)

**Migration Source**: `2026_07_11_000005_create_finance_part2_domain.php`
**Model Source**: `App\Domains\Finance\Models\JournalEntryLine`

---

## Table: `payments`

**Purpose**: Payment/receipt records with polymorphic contact linkage and multi-currency support.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| branch_id | uuid | No | — | Composite FK |
| payment_number | string(50) | No | — | |
| payment_date | timestamp | No | CURRENT_TIMESTAMP | |
| payment_method_id | uuid | No | — | Composite FK |
| chart_of_account_id | uuid | No | — | Composite FK |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| amount | decimal(18,2) | No | — | |
| base_amount | decimal(18,2) | No | — | |
| payment_type | string(20) | No | — | CHECK: Receipt, Payment, Refund, Adjustment, Transfer |
| contact_type | string(20) | Yes | — | CHECK: Customer, Supplier, Employee, Other |
| contact_id | uuid | Yes | — | Polymorphic |
| status | string(20) | No | 'Draft' | CHECK: Draft, Posted, Reversed |
| notes | text | Yes | — | |
| created_by | uuid | No | — | FK → users |
| posted_by | uuid | Yes | — | FK → users |
| posted_at | timestamp | Yes | — | |
| reversed_by | uuid | Yes | — | FK → users |
| reversed_at | timestamp | Yes | — | |
| reversal_reason | text | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (RESTRICT); `posted_by` → users.id (RESTRICT); `reversed_by` → users.id (RESTRICT); composite `(business_id, branch_id)` → branches; composite `(business_id, payment_method_id)` → payment_methods; composite `(business_id, chart_of_account_id)` → chart_of_accounts
**Unique Constraints**: `(business_id, id)`, `(business_id, payment_number)`
**Check Constraints**: `chk_pay_type`, `chk_pay_contact_type`, `chk_pay_status`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Payment`):
- belongsTo → Business, Branch, PaymentMethod, ChartOfAccount, Currency, User (createdBy, postedBy, reversedBy)
- morphTo → contact (contact_type, contact_id)
- hasMany → PaymentAllocation (allocations)

**Migration Source**: `2026_07_11_000005_create_finance_part2_domain.php`
**Model Source**: `App\Domains\Finance\Models\Payment`

---

## Table: `payment_allocations`

**Purpose**: Allocation of a payment to one or more documents (invoices, returns, etc.).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| payment_id | uuid | No | — | Composite FK |
| amount | decimal(18,2) | No | — | CHECK: > 0 |
| document_type | string(50) | No | — | Polymorphic |
| document_id | uuid | No | — | Polymorphic |
| created_by | uuid | No | — | FK → users |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); composite `(business_id, payment_id)` → payments (CASCADE); `created_by` → users.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Indexes**: `idx_payment_allocations_doc` on (document_type, document_id)
**Check Constraints**: `chk_pa_amount`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `PaymentAllocation`):
- belongsTo → Business, Payment, User (createdBy)
- morphTo → document (document_type, document_id)

**Migration Source**: `2026_07_11_000005_create_finance_part2_domain.php`
**Model Source**: `App\Domains\Finance\Models\PaymentAllocation`

---

## Table: `expense_categories`

**Purpose**: Expense classification categories linked to chart of accounts.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| chart_of_account_id | uuid | No | — | Composite FK |
| category_name | string(100) | No | — | |
| description | text | Yes | — | |
| is_active | boolean | No | true | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); composite `(business_id, chart_of_account_id)` → chart_of_accounts (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, category_name)`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `ExpenseCategory`):
- belongsTo → Business, ChartOfAccount
- hasMany → Expense

**Migration Source**: `2026_07_11_000005_create_finance_part2_domain.php`
**Model Source**: `App\Domains\Finance\Models\ExpenseCategory`

---

## Table: `expenses`

**Purpose**: Individual expense records with category, payment method, and multi-currency support.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| branch_id | uuid | No | — | Composite FK |
| expense_category_id | uuid | No | — | Composite FK |
| expense_number | string(50) | No | — | |
| expense_date | timestamp | No | CURRENT_TIMESTAMP | |
| payment_method_id | uuid | No | — | Composite FK |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| amount | decimal(18,2) | No | — | |
| base_amount | decimal(18,2) | No | — | |
| tax_amount | decimal(18,2) | No | 0.00 | |
| reference_number | string(100) | Yes | — | |
| status | string(20) | No | 'Draft' | CHECK: Draft, Posted, Cancelled |
| notes | text | Yes | — | |
| created_by | uuid | No | — | FK → users |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (RESTRICT); composite `(business_id, branch_id)` → branches; composite `(business_id, expense_category_id)` → expense_categories; composite `(business_id, payment_method_id)` → payment_methods
**Unique Constraints**: `(business_id, id)`, `(business_id, expense_number)`
**Check Constraints**: `chk_exp_status`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Expense`):
- belongsTo → Business, Branch, ExpenseCategory, PaymentMethod, Currency, User (createdBy)

**Migration Source**: `2026_07_11_000005_create_finance_part2_domain.php`
**Model Source**: `App\Domains\Finance\Models\Expense`

---

## Table: `opening_balances`

**Purpose**: Opening balance entries per fiscal year per chart of account, with multi-currency support.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| fiscal_year_id | uuid | No | — | Composite FK |
| chart_of_account_id | uuid | No | — | Composite FK |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| debit_amount | decimal(18,2) | No | 0.00 | |
| credit_amount | decimal(18,2) | No | 0.00 | |
| base_debit_amount | decimal(18,2) | No | 0.00 | |
| base_credit_amount | decimal(18,2) | No | 0.00 | |
| created_by | uuid | No | — | FK → users |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (RESTRICT); composite `(business_id, fiscal_year_id)` → fiscal_years; composite `(business_id, chart_of_account_id)` → chart_of_accounts
**Unique Constraints**: `(fiscal_year_id, chart_of_account_id)`
**Check Constraints**: `chk_ob_xor` (either debit or credit, not both), `chk_ob_base_xor`
**Triggers**: `trg_opening_bal_match` — validates fiscal year and COA belong to same business
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `OpeningBalance`):
- belongsTo → Business, FiscalYear, ChartOfAccount, Currency

**Migration Source**: `2026_07_11_000005_create_finance_part2_domain.php`
**Model Source**: `App\Domains\Finance\Models\OpeningBalance`

---

---

# DOMAIN 8 — EXTENDED DOMAINS (Part 1: Channels, Carts, Settings, HR & Taxes)

---

## Table: `product_channels` (Pivot)

**Purpose**: Many-to-many pivot associating product units with sales channels, including custom pricing and availability.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| business_id | uuid | No | — | Composite FK |
| product_unit_id | uuid | No | — | Composite FK |
| channel_id | uuid | No | — | Composite FK |
| price | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| is_available | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `(product_unit_id, channel_id)` — composite
**Foreign Keys**: composite `(business_id, product_unit_id)` → product_units (CASCADE); composite `(business_id, channel_id)` → channels (CASCADE)
**Check Constraints**: `chk_pc_price` (price >= 0)
**Soft Deletes**: No
**Timestamps**: Yes
**Model Source**: *No dedicated model — accessed via belongsToMany pivot on Channel / ProductUnit*

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `carts`

**Purpose**: Shopping carts for channels/customers, supporting online orders and draft POS transactions.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses |
| channel_id | uuid | No | — | Composite FK |
| customer_id | uuid | Yes | — | Composite FK |
| session_id | string(255) | Yes | — | |
| currency_id | uuid | No | — | FK → currencies |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| sub_total | decimal(18,2) | No | 0.00 | |
| discount_total | decimal(18,2) | No | 0.00 | |
| tax_total | decimal(18,2) | No | 0.00 | |
| grand_total | decimal(18,2) | No | 0.00 | |
| status | string(20) | No | 'Active' | CHECK: Active, Converted, Abandoned |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); composite `(business_id, channel_id)` → channels (CASCADE); `customer_id` → No FK constraint in PostgreSQL migration (Customer owned by SQLite ERP)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_cart_status`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `Cart`):
- belongsTo → Business, Channel, Customer, Currency
- hasMany → CartItem (items)

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\Sales\Models\Cart`

---

## Table: `cart_items`

**Purpose**: Individual line items within a shopping cart.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| cart_id | uuid | No | — | Composite FK |
| product_unit_id | uuid | No | — | Composite FK |
| quantity | decimal(18,3) | No | — | CHECK: > 0 |
| unit_price | decimal(18,2) | No | — | CHECK: >= 0 |
| discount | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| tax | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| line_total | decimal(18,2) | No | — | CHECK: >= 0 |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, cart_id)` → carts (CASCADE); composite `(business_id, product_unit_id)` → product_units (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_cart_item_qty` (> 0), `chk_cart_item_price` (>= 0), `chk_cart_item_discount` (>= 0), `chk_cart_item_tax` (>= 0), `chk_cart_item_total` (>= 0)
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `CartItem`):
- belongsTo → Business, Cart, ProductUnit

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\Sales\Models\CartItem`

---

## Table: `system_settings`

**Purpose**: Key-value system configuration store per business with JSONB type-safe storage.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| setting_key | string(100) | No | — | |
| setting_value | jsonb | Yes | — | JSONB data structure |
| setting_type | string(20) | No | 'string' | CHECK: string, integer, boolean, json |
| is_public | boolean | No | false | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE)
**Unique Constraints**: `(business_id, id)`, `(business_id, setting_key)`
**Check Constraints**: `chk_ss_type`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `SystemSetting`):
- belongsTo → Business

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\Extended\Models\SystemSetting`

---

## Table: `print_settings`

**Purpose**: Document printing and layout configurations per business or specific branch.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| branch_id | uuid | Yes | — | Composite FK (NULL = global business setting) |
| document_type | string(50) | No | — | e.g. SalesInvoice, Receipt |
| template_name | string(100) | No | 'default' | |
| header_text | text | Yes | — | |
| footer_text | text | Yes | — | |
| show_logo | boolean | No | true | |
| show_tax_summary | boolean | No | true | |
| show_qr_code | boolean | No | true | |
| paper_size | string(20) | No | 'A4' | CHECK: A4, A5, Thermal80mm, Thermal58mm |
| margin_top | integer | No | 10 | |
| margin_bottom | integer | No | 10 | |
| margin_left | integer | No | 10 | |
| margin_right | integer | No | 10 | |
| font_size | integer | No | 12 | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); composite `(business_id, branch_id)` → branches (CASCADE)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_ps_paper_size`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `PrintSetting`):
- belongsTo → Business, Branch

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\Extended\Models\PrintSetting`

---

## Table: `sequences`

**Purpose**: Sequential document numbering generators (e.g., INV-2026-00001) per business and branch.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| branch_id | uuid | Yes | — | Composite FK (NULL = business-wide) |
| document_type | string(50) | No | — | e.g., SalesInvoice, PurchaseInvoice |
| prefix | string(20) | Yes | — | |
| suffix | string(20) | Yes | — | |
| current_value | bigint | No | 0 | CHECK: >= 0 |
| step | integer | No | 1 | CHECK: > 0 |
| padding | integer | No | 5 | CHECK: > 0 |
| reset_frequency | string(20) | No | 'Never' | CHECK: Never, Daily, Monthly, Yearly |
| last_reset_date | date | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); composite `(business_id, branch_id)` → branches (CASCADE)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_seq_val` (current_value >= 0), `chk_seq_step` (> 0), `chk_seq_pad` (> 0), `chk_seq_reset`
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `Sequence`):
- *No dedicated model or relationships explicitly defined in model scan*

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `departments`

**Purpose**: Human Resources departments hierarchy per business.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| department_name | string(100) | No | — | |
| department_code | string(50) | Yes | — | |
| parent_id | uuid | Yes | — | Self-referential composite FK |
| manager_id | uuid | Yes | — | Composite FK → employees (nullable initially) |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); composite `(business_id, parent_id)` → departments (self, RESTRICT); composite `(business_id, manager_id)` → employees (SET NULL)
**Unique Constraints**: `(business_id, id)`, `(business_id, department_name)`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `Department`):
- belongsTo → Business, Employee (manager)
- hasMany → Employee (employees)

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\HR\Models\Department`

---

## Table: `job_titles`

**Purpose**: Employee job titles classification per business.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| title_name | string(100) | No | — | |
| description | text | Yes | — | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE)
**Unique Constraints**: `(business_id, id)`, `(business_id, title_name)`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `JobTitle`):
- *No dedicated model explicitly scanned or defined*

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `employees`

**Purpose**: Employee personnel records linked optionally to a system user account and department.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| user_id | uuid | Yes | — | FK → users (SET NULL) |
| employee_code | string(50) | No | — | |
| first_name | string(100) | No | — | |
| last_name | string(100) | No | — | |
| email | string(255) | Yes | — | |
| phone | string(30) | Yes | — | |
| hire_date | date | No | — | |
| termination_date | date | Yes | — | CHECK: >= hire_date |
| department_id | uuid | Yes | — | Composite FK → departments |
| job_title_id | uuid | Yes | — | Composite FK → job_titles |
| salary | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| currency_id | uuid | No | — | FK → currencies |
| status | string(20) | No | 'Active' | CHECK: Active, Terminated, OnLeave |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); `user_id` → users.id (SET NULL); `currency_id` → currencies.id (RESTRICT); composite `(business_id, department_id)` → departments (SET NULL); composite `(business_id, job_title_id)` → job_titles (SET NULL)
**Unique Constraints**: `(business_id, id)`, `(business_id, employee_code)`, `(business_id, user_id)`
**Check Constraints**: `chk_emp_dates`, `chk_emp_salary`, `chk_emp_status`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships** (from Model `Employee`):
- belongsTo → Business, User, Department, Currency
- hasMany → AttendanceRecord, PayrollSlip, Department (managedDepartments)

> **Note on HR Models Without Migrations**: Models `AttendanceRecord` (`attendance_records`) and `PayrollSlip` (`payroll_slips`) exist in `App\Domains\HR\Models\`, but **do not have corresponding tables created in the migrations**. They represent pending or planned database structures.

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\HR\Models\Employee`

---

## Table: `employee_documents`

**Purpose**: Employee files, identification documents, and certificates storage tracking.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| employee_id | uuid | No | — | Composite FK |
| document_type | string(50) | No | — | e.g. ID, Passport, Contract |
| document_number | string(100) | Yes | — | |
| file_path | string(500) | No | — | |
| issue_date | date | Yes | — | |
| expiry_date | date | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, employee_id)` → employees (CASCADE)
**Unique Constraints**: `(business_id, id)`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships**: Associated with Employee.

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `taxes`

**Purpose**: Tax rates definitions per business (e.g., VAT 15%, Zero-Rated).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| tax_name | string(100) | No | — | |
| tax_code | string(50) | No | — | |
| rate | decimal(8,4) | No | — | CHECK: >= 0 |
| tax_type | string(20) | No | 'Percentage' | CHECK: Percentage, Fixed |
| is_default | boolean | No | false | |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE)
**Unique Constraints**: `(business_id, id)`, `(business_id, tax_code)`
**Check Constraints**: `chk_tax_rate`, `chk_tax_type`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `Tax`):
- belongsTo → Business
- Associated with Products and Invoice Items.

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\Finance\Models\Tax`

---

---

# DOMAIN 8 — EXTENDED DOMAINS (Part 2: Variants, Adjustments, Assets, & Reconciliations)

---

## Table: `product_taxes` (Pivot)

**Purpose**: Many-to-many pivot linking product units with applicable tax rates.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| business_id | uuid | No | — | Composite FK |
| product_unit_id | uuid | No | — | Composite FK |
| tax_id | uuid | No | — | Composite FK |

**Primary Key**: `(business_id, product_unit_id, tax_id)` — composite
**Foreign Keys**: composite `(business_id, product_unit_id)` → product_units (CASCADE); composite `(business_id, tax_id)` → taxes (CASCADE)
**Soft Deletes**: No
**Timestamps**: No
**Model Source**: *No dedicated model — accessed via belongsToMany pivot*

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `product_variants`

**Purpose**: Product attributes options and values (e.g., Size: Large, Color: Red) per product unit.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| product_unit_id | uuid | No | — | Composite FK |
| variant_name | string(100) | No | — | e.g. Color, Size |
| variant_value | string(100) | No | — | e.g. Red, XL |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); composite `(business_id, product_unit_id)` → product_units (CASCADE)
**Unique Constraints**: `(product_unit_id, variant_name)`
**Soft Deletes**: No
**Timestamps**: No

**Relationships**: Associated with ProductUnit.

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `stock_adjustments`

**Purpose**: Inventory physical count adjustment headers (increases, decreases, damage, loss).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (RESTRICT) |
| warehouse_id | uuid | No | — | Composite FK |
| adjustment_number | string(50) | No | — | |
| adjustment_date | timestamp | No | CURRENT_TIMESTAMP | |
| adjustment_type | string(20) | No | — | CHECK: Increase, Decrease, Damage, Loss |
| status | string(20) | No | 'Draft' | CHECK: Draft, Posted |
| notes | text | Yes | — | |
| created_by | uuid | No | — | FK → users (RESTRICT) |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |
| deleted_at | timestamp | Yes | — | Soft Delete |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); composite `(business_id, warehouse_id)` → warehouses (RESTRICT); `created_by` → users.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, adjustment_number)`
**Check Constraints**: `chk_sa_type`, `chk_sa_status`
**Soft Deletes**: Yes
**Timestamps**: Yes

**Relationships**: Associated with Warehouse and User (createdBy), hasMany `StockAdjustmentItem`.

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `stock_adjustment_items`

**Purpose**: Line items for stock adjustments comparing system quantity vs physical quantity.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| adjustment_id | uuid | No | — | Composite FK |
| product_unit_id | uuid | No | — | Composite FK |
| system_qty | decimal(18,3) | No | — | |
| physical_qty | decimal(18,3) | No | — | |
| diff_qty | decimal(18,3) | No | — | CHECK: diff_qty = physical_qty - system_qty |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, adjustment_id)` → stock_adjustments (CASCADE); composite `(business_id, product_unit_id)` → product_units (RESTRICT)
**Check Constraints**: `chk_sai_diff` (`diff_qty = physical_qty - system_qty`)
**Soft Deletes**: No
**Timestamps**: No

**Relationships**: Associated with StockAdjustment and ProductUnit.

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `attachments`

**Purpose**: Polymorphic file attachments across all business entities (invoices, contracts, expenses, etc.).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| entity_type | string(50) | No | — | Polymorphic |
| entity_id | uuid | No | — | Polymorphic |
| file_path | string(500) | No | — | |
| file_name | string(255) | No | — | |
| upload_date | timestamp | No | CURRENT_TIMESTAMP | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE)
**Indexes**: `idx_attachments_entity` on (business_id, entity_type, entity_id)
**Soft Deletes**: No
**Timestamps**: Only `upload_date`

**Relationships**: Polymorphic relationship `entity()` to any model.

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `activity_logs`

**Purpose**: System audit trail and activity log tracking user actions across entities.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| user_id | uuid | Yes | — | FK → users (SET NULL) |
| action | string(100) | No | — | e.g. create, update, post, reverse |
| entity_type | string(50) | No | — | Polymorphic |
| entity_id | uuid | Yes | — | Polymorphic |
| details | jsonb | Yes | — | JSONB delta or context |
| ip_address | string(45) | Yes | — | |
| created_at | timestamp | No | CURRENT_TIMESTAMP | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); `user_id` → users.id (SET NULL)
**Indexes**: `idx_activity_logs_lookup` on (business_id, entity_type, entity_id)
**Soft Deletes**: No
**Timestamps**: Only `created_at`

**Relationships**: Associated with Business and User.

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`

---

## Table: `fixed_assets`

**Purpose**: Fixed assets register tracking acquisition, useful life, and depreciation methods.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (RESTRICT) |
| branch_id | uuid | Yes | — | Composite FK |
| asset_category_id | uuid | Yes | — | FK |
| currency_id | uuid | No | — | FK → currencies (RESTRICT) |
| asset_code | string(50) | No | — | |
| asset_name | string(255) | No | — | |
| acquisition_date | date | No | — | |
| acquisition_cost | decimal(18,2) | No | — | CHECK: >= 0 |
| base_acquisition_cost | decimal(18,2) | No | — | CHECK: >= 0 |
| useful_life | integer | No | — | CHECK: > 0 (in periods/months) |
| residual_value | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| base_residual_value | decimal(18,2) | No | 0.00 | CHECK: >= 0 |
| depreciation_method | string(50) | No | — | e.g. StraightLine |
| depreciation_start_date | date | No | — | |
| status | string(30) | No | 'Draft' | CHECK: Draft, Active, Depreciating, Fully Depreciated, Disposed |
| responsible_user_id | uuid | Yes | — | FK → users (SET NULL) |
| created_by | uuid | No | — | FK → users (RESTRICT) |
| updated_by | uuid | Yes | — | FK → users (SET NULL) |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); `created_by` → users.id (RESTRICT); `updated_by` → users.id (SET NULL); `responsible_user_id` → users.id (SET NULL); composite `(business_id, branch_id)` → branches (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, asset_code)`
**Check Constraints**: `chk_fa_status`, `chk_fa_cost`, `chk_fa_life`, `chk_fa_residual`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `FixedAsset`):
- belongsTo → Business, Branch, AssetCategory, Currency, User (responsibleUser, creator, updater)
- hasMany → DepreciationSchedule (depreciationSchedules)

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\FixedAssets\Models\FixedAsset`

---

## Table: `depreciation_schedules`

**Purpose**: Periodic depreciation schedule entries for fixed assets over their useful life.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| fixed_asset_id | uuid | No | — | Composite FK |
| depreciation_period | integer | No | — | Period number |
| scheduled_posting_date | date | No | — | |
| depreciation_amount | decimal(18,2) | No | — | CHECK: >= 0 |
| base_depreciation_amount | decimal(18,2) | No | — | CHECK: >= 0 |
| accumulated_depreciation | decimal(18,2) | No | — | |
| base_accumulated_depreciation | decimal(18,2) | No | — | |
| remaining_book_value | decimal(18,2) | No | — | |
| base_remaining_book_value | decimal(18,2) | No | — | |
| status | string(30) | No | 'Pending' | CHECK: Pending, Ready, Posted, Cancelled |
| created_by | uuid | No | — | FK → users (RESTRICT) |
| updated_by | uuid | Yes | — | FK → users (SET NULL) |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, fixed_asset_id)` → fixed_assets (CASCADE); `created_by` → users.id (RESTRICT); `updated_by` → users.id (SET NULL)
**Unique Constraints**: `uq_dep_schedule_period` on (business_id, fixed_asset_id, depreciation_period)
**Check Constraints**: `chk_ds_status`, `chk_ds_amount`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `DepreciationSchedule`):
- belongsTo → FixedAsset, User (creator, updater)

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\FixedAssets\Models\DepreciationSchedule`

---

## Table: `bank_reconciliations`

**Purpose**: Periodic statement reconciliations comparing bank statement balance against system ledger balance.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (RESTRICT) |
| chart_of_account_id | uuid | No | — | Composite FK → chart_of_accounts (RESTRICT) |
| statement_date | date | No | — | |
| statement_balance | decimal(18,2) | No | — | |
| system_balance | decimal(18,2) | No | — | |
| difference | decimal(18,2) | No | — | |
| status | string(20) | No | 'Draft' | CHECK: Draft, Completed |
| created_by | uuid | No | — | FK → users (RESTRICT) |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); composite `(business_id, chart_of_account_id)` → chart_of_accounts (RESTRICT); `created_by` → users.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `uq_bank_recon_date` on (business_id, chart_of_account_id, statement_date)
**Check Constraints**: `chk_br_status`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships** (from Model `BankReconciliation`):
- belongsTo → Business, ChartOfAccount, User (createdBy)
- hasMany → BankReconciliationLine (lines)

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\Finance\Models\BankReconciliation`

---

## Table: `bank_reconciliation_lines`

**Purpose**: Individual transaction check lines cleared or uncleared during a bank reconciliation.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| bank_reconciliation_id | uuid | No | — | Composite FK |
| payment_id | uuid | No | — | Composite FK → payments (RESTRICT) |
| is_cleared | boolean | No | false | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, bank_reconciliation_id)` → bank_reconciliations (CASCADE); composite `(business_id, payment_id)` → payments (RESTRICT)
**Soft Deletes**: No
**Timestamps**: No

**Relationships** (from Model `BankReconciliationLine`):
- belongsTo → Business, BankReconciliation, JournalEntryLine (or Payment depending on model definition)

**Migration Source**: `2026_07_11_000006_create_extended_domains.php`
**Model Source**: `App\Domains\Finance\Models\BankReconciliationLine`

---

---

# DOMAIN 9 — SPECIALIZED MODULES & LEDGERS

---

## Table: `account_mappings`

**Purpose**: System default posting rules mapping transaction events to chart of accounts (e.g. Sales Tax Payable, Inventory Control).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (CASCADE) |
| mapping_key | string(100) | No | — | e.g., default_sales_tax, inventory_asset |
| mapping_name | string(150) | No | — | Human-readable description |
| chart_of_account_id | uuid | No | — | Composite FK → chart_of_accounts (RESTRICT) |
| is_active | boolean | No | true | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (CASCADE); composite `(business_id, chart_of_account_id)` → chart_of_accounts (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, mapping_key)`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships**: Associated with Business and ChartOfAccount.

**Migration Source**: `2026_07_14_000001_create_account_mappings_table.php`
**Model Source**: `App\Domains\Finance\Models\AccountMapping`

---

## Table: `customer_receivables`

**Purpose**: Accounts Receivable (A/R) sub-ledger tracking open invoices, paid amounts, due dates, and aging per customer.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (RESTRICT) |
| customer_id | uuid | No | — | Composite FK → customers (RESTRICT) |
| sales_invoice_id | uuid | No | — | Composite FK → sales_invoices (RESTRICT) |
| currency_id | uuid | No | — | FK → currencies (RESTRICT) |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| original_amount | decimal(18,2) | No | — | |
| base_original_amount | decimal(18,2) | No | — | |
| paid_amount | decimal(18,2) | No | 0.00 | |
| base_paid_amount | decimal(18,2) | No | 0.00 | |
| remaining_amount | decimal(18,2) | No | — | |
| base_remaining_amount | decimal(18,2) | No | — | |
| due_date | date | Yes | — | |
| status | string(20) | No | 'Unpaid' | CHECK: Unpaid, Partial, Paid |
| last_payment_date | date | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); composite `(business_id, customer_id)` → customers (RESTRICT); composite `(business_id, sales_invoice_id)` → sales_invoices (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, sales_invoice_id)`
**Check Constraints**: `chk_cr_status` (status IN ('Unpaid','Partial','Paid'))
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships**: Associated with Customer and SalesInvoice, hasMany `ReceivableEntry`.

**Migration Source**: `2026_07_16_000001_create_accounts_receivable_tables.php`

---

## Table: `receivable_entries`

**Purpose**: Detailed tracking history of payment allocations against accounts receivable records.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| customer_receivable_id | uuid | No | — | Composite FK → customer_receivables (CASCADE) |
| payment_id | uuid | Yes | — | Composite FK → payments (SET NULL) |
| payment_allocation_id | uuid | Yes | — | composite FK → payment_allocations (SET NULL) |
| entry_date | timestamp | No | CURRENT_TIMESTAMP | |
| amount | decimal(18,2) | No | — | |
| base_amount | decimal(18,2) | No | — | |
| entry_type | string(20) | No | 'Payment' | CHECK: Payment, Adjustment, WriteOff |
| created_by | uuid | No | — | FK → users (RESTRICT) |
| created_at | timestamp | No | CURRENT_TIMESTAMP | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, customer_receivable_id)` → customer_receivables (CASCADE); composite `(business_id, payment_id)` → payments (SET NULL); composite `(business_id, payment_allocation_id)` → payment_allocations (SET NULL); `created_by` → users.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_re_type`
**Soft Deletes**: No
**Timestamps**: Only `created_at`

**Relationships**: Associated with CustomerReceivable and Payment.

**Migration Source**: `2026_07_16_000001_create_accounts_receivable_tables.php`

---

## Table: `supplier_payables`

**Purpose**: Accounts Payable (A/P) sub-ledger tracking open purchase invoices, paid amounts, due dates, and aging per supplier.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (RESTRICT) |
| supplier_id | uuid | No | — | Composite FK → suppliers (RESTRICT) |
| purchase_invoice_id | uuid | No | — | Composite FK → purchase_invoices (RESTRICT) |
| currency_id | uuid | No | — | FK → currencies (RESTRICT) |
| exchange_rate | decimal(18,8) | No | 1.00000000 | |
| original_amount | decimal(18,2) | No | — | |
| base_original_amount | decimal(18,2) | No | — | |
| paid_amount | decimal(18,2) | No | 0.00 | |
| base_paid_amount | decimal(18,2) | No | 0.00 | |
| remaining_amount | decimal(18,2) | No | — | |
| base_remaining_amount | decimal(18,2) | No | — | |
| due_date | date | Yes | — | |
| status | string(20) | No | 'Unpaid' | CHECK: Unpaid, Partial, Paid |
| last_payment_date | date | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `currency_id` → currencies.id (RESTRICT); composite `(business_id, supplier_id)` → suppliers (RESTRICT); composite `(business_id, purchase_invoice_id)` → purchase_invoices (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, purchase_invoice_id)`
**Check Constraints**: `chk_sp_status`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships**: Associated with Supplier and PurchaseInvoice, hasMany `PayableEntry`.

**Migration Source**: `2026_07_16_000002_create_accounts_payable_tables.php`

---

## Table: `payable_entries`

**Purpose**: Detailed tracking history of payment allocations against accounts payable records.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | Composite FK |
| supplier_payable_id | uuid | No | — | Composite FK → supplier_payables (CASCADE) |
| payment_id | uuid | Yes | — | Composite FK → payments (SET NULL) |
| payment_allocation_id | uuid | Yes | — | composite FK → payment_allocations (SET NULL) |
| entry_date | timestamp | No | CURRENT_TIMESTAMP | |
| amount | decimal(18,2) | No | — | |
| base_amount | decimal(18,2) | No | — | |
| entry_type | string(20) | No | 'Payment' | CHECK: Payment, Adjustment, WriteOff |
| created_by | uuid | No | — | FK → users (RESTRICT) |
| created_at | timestamp | No | CURRENT_TIMESTAMP | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: composite `(business_id, supplier_payable_id)` → supplier_payables (CASCADE); composite `(business_id, payment_id)` → payments (SET NULL); composite `(business_id, payment_allocation_id)` → payment_allocations (SET NULL); `created_by` → users.id (RESTRICT)
**Unique Constraints**: `(business_id, id)`
**Check Constraints**: `chk_pe_type`
**Soft Deletes**: No
**Timestamps**: Only `created_at`

**Relationships**: Associated with SupplierPayable and Payment.

**Migration Source**: `2026_07_16_000002_create_accounts_payable_tables.php`

---

## Table: `accounting_periods`

**Purpose**: Financial accounting period close status management preventing modification of closed period data.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | No | gen_random_uuid() | PK |
| business_id | uuid | No | — | FK → businesses (RESTRICT) |
| fiscal_year_id | uuid | No | — | Composite FK → fiscal_years (RESTRICT) |
| period_number | integer | No | — | |
| period_name | string(50) | No | — | e.g. January 2026 |
| start_date | date | No | — | |
| end_date | date | No | — | |
| status | string(20) | No | 'Open' | CHECK: Open, Closed, Locked |
| closed_by | uuid | Yes | — | FK → users (SET NULL) |
| closed_at | timestamp | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (uuid)
**Foreign Keys**: `business_id` → businesses.id (RESTRICT); `closed_by` → users.id (SET NULL); composite `(business_id, fiscal_year_id)` → fiscal_years (RESTRICT)
**Unique Constraints**: `(business_id, id)`, `(business_id, fiscal_year_id, period_number)`
**Check Constraints**: `chk_ap_status` (status IN ('Open','Closed','Locked')), `chk_ap_dates` (end_date >= start_date)
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships**: Associated with FiscalYear and User (closedBy).

**Migration Source**: `2026_07_16_000003_create_financial_closing_tables.php`

---

## Table: `personal_access_tokens`

**Purpose**: Laravel Sanctum API authentication tokens table for mobile/desktop client access.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | bigint | No | Auto-increment | PK (BigIncrements) |
| tokenable_type | string(255) | No | — | Polymorphic (usually User) |
| tokenable_id | uuid | No | — | Polymorphic ID (UUID) |
| name | string(255) | No | — | Token name / device |
| token | string(64) | No | — | SHA-256 hashed token |
| abilities | text | Yes | — | JSON/text list of abilities |
| last_used_at | timestamp | Yes | — | |
| expires_at | timestamp | Yes | — | |
| created_at | timestamp | Yes | — | |
| updated_at | timestamp | Yes | — | |

**Primary Key**: `id` (bigint auto-increment)
**Indexes**: `personal_access_tokens_tokenable_type_tokenable_id_index`, `personal_access_tokens_token_unique`
**Soft Deletes**: No
**Timestamps**: Yes

**Relationships**: Polymorphic `tokenable()` pointing to User model.

**Migration Source**: `2026_07_17_151505_create_personal_access_tokens_table.php`

---

---

# DOMAIN 10 — BUSINESS RULES, DATABASE FUNCTIONS & TRIGGERS

---

This section documents all database-level procedural functions (`PL/pgSQL`) and triggers enforced directly inside PostgreSQL by `database/migrations/2026_07_11_000007_create_business_rule_triggers.php`.

| # | Function Name | Trigger Name | Target Table | Trigger Timing / Event | Purpose & Business Logic Enforced |
|---|---|---|---|---|---|
| **1** | `update_updated_at_column()` | `update_{table}_updated_at` | 36+ tables across all domains | `BEFORE UPDATE` | Automatically updates the `updated_at` column to `CURRENT_TIMESTAMP` whenever a row is modified. |
| **2** | `fn_system_settings_scope()` | `trg_system_settings_scope` | `system_settings` | `BEFORE INSERT OR UPDATE` | Sets `scope_business_id` to `COALESCE(NEW.business_id::TEXT, '__GLOBAL__')` for unique scoping. |
| **3** | `fn_sequences_scope()` | `trg_sequences_scope` | `sequences` | `BEFORE INSERT OR UPDATE` | Sets `branch_scope_id` to `COALESCE(NEW.branch_id::TEXT, '__GLOBAL__')` for branch or global document sequence isolation. |
| **4** | `fn_journal_balance_check()` | `trg_journal_balance_check` | `journal_entries` | `BEFORE UPDATE` | Prevents posting (`status = 'Posted'`) unless base debit total equals base credit total and neither total is zero. |
| **5** | `fn_sales_return_qty()` | `trg_sales_return_qty` | `sales_return_items` | `BEFORE INSERT OR UPDATE` | Prevents returning a quantity that exceeds the original sales invoice line item quantity across all returns. |
| **6** | `fn_purchase_return_qty()` | `trg_purchase_return_qty` | `purchase_return_items` | `BEFORE INSERT OR UPDATE` | Prevents returning a quantity that exceeds the original purchase invoice line item quantity across all returns. |
| **7** | `fn_bank_recon_match()` | `trg_bank_recon_match` | `bank_reconciliation_lines` | `BEFORE INSERT OR UPDATE` | Ensures the payment being cleared belongs to the exact same bank chart of account (`chart_of_account_id`) and currency (`currency_id`) as the reconciliation header. |
| **8** | `fn_stock_adj_logic()` | `trg_stock_adj_logic` | `stock_adjustment_items` | `BEFORE INSERT OR UPDATE` | Validates sign consistency: `Increase` must have `diff_qty > 0`, while `Decrease`, `Damage`, or `Loss` must have `diff_qty < 0`. |
| **9** | `fn_opening_bal_match()` | `trg_opening_bal_match` | `opening_balances` | `BEFORE INSERT OR UPDATE` | Validates that the referenced `fiscal_year_id` and `chart_of_account_id` belong to the exact same `business_id`. |
| **10** | `fn_fiscal_period_overlap()` | `trg_fiscal_period_overlap` | `fiscal_periods` | `BEFORE INSERT OR UPDATE` | Prevents overlapping date intervals (`start_date`, `end_date`) within the same fiscal year (`fiscal_year_id`). |

---

# SQLITE OFFLINE-FIRST TRANSITION & COMPATIBILITY ANALYSIS

Because this schema extraction serves as the technical roadmap for migrating the Smart Merchant ERP system from **PostgreSQL (Server/Cloud)** to an **Offline-First SQLite (Local/Edge)** architecture, the following architectural adjustments and gotchas must be addressed during the transition:

## 1. Primary Key Generation (`gen_random_uuid()`)
- **Current State**: Virtually all 60+ tables use `uuid` as their primary key with `default(DB::raw('gen_random_uuid()'))`.
- **SQLite Impact**: SQLite does not have a native `gen_random_uuid()` function.
- **Action Required**:
  - UUID generation must either be handled at the application/ORM level (`Illuminate\Database\Eloquent\Concerns\HasUuids` in Laravel / client UUID generator in Flutter/Frontend before insert), OR
  - Custom SQLite user functions or triggers must be injected if database-level generation is strictly required.

## 2. JSON/JSONB Column Types
- **Current State**: Several critical tables utilize `jsonb` (`system_settings.setting_value`, `activity_logs.details`).
- **SQLite Impact**: SQLite treats `JSON` columns as standard `TEXT` columns stored with stringified JSON, but offers built-in `json_extract()` and `json_patch()` functions.
- **Action Required**:
  - Convert `jsonb` schema declarations to `json` / `text` in SQLite migrations.
  - Ensure application logic parses and serializes JSON objects gracefully without relying on binary JSONB operators (`->>`, `@>`).

## 3. Database-Level Business Triggers (`PL/pgSQL`)
- **Current State**: 10 complex procedural functions and triggers enforce core business rules (e.g. journal entry double-entry balancing, return quantity thresholds, bank reconciliation account matching).
- **SQLite Impact**: SQLite does **not** support `PL/pgSQL` procedural language or variables (`DECLARE`, `SELECT INTO`). While SQLite supports basic `CREATE TRIGGER ... BEGIN ... END;` with `RAISE(ABORT, 'message')`, complex queries across multiple tables inside triggers can degrade SQLite write performance or cause locking (`SQLITE_BUSY`).
- **Action Required**:
  - Re-implement complex business validations (such as `fn_journal_balance_check`, `fn_sales_return_qty`, `fn_purchase_return_qty`) inside Laravel Domain Services / Action Classes or Repository layers prior to database commits, OR
  - Translate simple validation rules (`fn_stock_adj_logic`, `fn_opening_bal_match`) to lightweight SQLite `EXISTS` queries inside `BEFORE INSERT/UPDATE` triggers using `SELECT RAISE(ABORT, 'Message') WHERE ...`.

## 4. Multi-Tenant Composite Foreign Keys & Isolation
- **Current State**: Highly disciplined multi-tenant composite foreign keys (`business_id` included on almost all foreign keys with composite unique keys).
- **SQLite Impact**: SQLite fully supports composite foreign keys (`FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id)`), **provided** `PRAGMA foreign_keys = ON;` is explicitly enabled on every SQLite database connection upon opening.
- **Action Required**:
  - Ensure the SQLite connection bootstrapper executes `PRAGMA foreign_keys = ON;` globally.

## 5. Summary of Schema Health & Missing Models/Migrations
During this complete extraction from actual source code, the following discrepancies between Eloquent Models and Migration Tables were identified:
- **Models Without Migrations**:
  - `AttendanceRecord` (`app/Domains/HR/Models/AttendanceRecord.php` → expects `attendance_records` table).
  - `PayrollSlip` (`app/Domains/HR/Models/PayrollSlip.php` → expects `payroll_slips` table).
- **Empty Models / Interfaces**:
  - `Unit` (`app/Domains/Catalog/Models/Unit.php` exists as an empty file/placeholder; table definition `units` is located in Migration 2).

---

**End of Database Schema Extraction Document.**
*Source of Truth Verified against `smart_merchant_core/database/migrations/*` and `smart_merchant_core/app/Domains/*`.*
