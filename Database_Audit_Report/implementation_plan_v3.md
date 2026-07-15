# 📋 Implementation Plan — Smart Merchant ERP Database v3.0

## 🎯 Objective
Create a **new, final PostgreSQL-compatible** database schema applying all audit findings.

---

## 🔧 Major Changes

### PostgreSQL Conversion
- `CHAR(36) DEFAULT (UUID())` → `UUID DEFAULT gen_random_uuid()`
- `ENUM(...)` → `VARCHAR + CHECK` constraints
- `ON UPDATE CURRENT_TIMESTAMP` → Trigger function `fn_set_updated_at()`
- MySQL triggers → PostgreSQL `CREATE FUNCTION` + `CREATE TRIGGER`
- `SIGNAL SQLSTATE '45000'` → `RAISE EXCEPTION`
- Remove `ENGINE=InnoDB`, `CHARSET`, `COLLATE`
- `JSON` → `JSONB`
- `BIGINT UNSIGNED` → `BIGINT` with CHECK
- `GENERATED ALWAYS AS ... STORED` → keep (PG 12+ supports it)
- Sentinel patterns → **Replace with PostgreSQL Partial Unique Indexes** (cleaner!)

### Audit Fixes Applied
1. 🔴 Add `payment_status` to `purchase_invoices`
2. 🟠 Composite FK for `categories.parent_id`
3. 🟠 Composite FK for `chart_of_accounts.parent_account_id`
4. 🟠 Add `chart_of_account_id` + `depreciation_account_id` to `fixed_assets`
5. 🟡 UNIQUE (account_id, business_name) on `businesses`
6. 🟡 `billing_cycle` CHECK constraint on `plans`
7. 🟡 Add timestamps to `plans`, `updated_at` to `roles`
8. 🟡 UNIQUE on `unit_name`, `plan_name`
9. 🟡 UNIQUE (product_id, unit_id) on `product_units`
10. 🟡 UNIQUE (transfer_id, product_unit_id) on `inventory_transfer_items`
11. 🟡 Unify `suppliers.credit_limit` to NOT NULL
12. 🟡 CHECK opening_balance_type consistency
13. 🟡 Add `employee_code` to `employees`
14. 🟡 Add `business_id` to `product_variants`
15. 🟡 CHECK normal_balance ↔ account_type in COA

### Table Reordering (minimize ALTER TABLE)
Move `currencies` early (before `plans`) so most FKs are inline.

**Only 1 ALTER TABLE needed**: `users.default_branch_id` → `user_branches` (circular)

---

## 📐 Domain Execution Order

| Step | Domain | Tables |
|------|--------|--------|
| 1 | Utility | `fn_set_updated_at()` trigger function |
| 2 | CORE Part 1 | accounts, currencies, businesses, branches, plans, subscriptions, subscription_payments |
| 3 | CORE Part 2 | permissions, roles, users, user_roles, role_permissions, user_branches + ALTER users |
| 4 | CATALOG | units, categories, brands, products, product_units, branch_product_prices, product_images |
| 5 | INVENTORY | warehouses, inventories, inventory_transactions, inventory_transfers, inventory_transfer_items |
| 6 | FINANCE Part 1 | fiscal_years, fiscal_periods, chart_of_accounts, payment_terms, payment_methods |
| 7 | SALES | customers, channels, sales_invoices, orders, order_items, sales_invoice_items, sales_returns, sales_return_items |
| 8 | PURCHASING | suppliers, purchase_invoices, purchase_invoice_items, purchase_returns, purchase_return_items |
| 9 | FINANCE Part 2 | journal_entries, journal_entry_lines, payments, expense_categories, expenses, opening_balances |
| 10 | SALES CHANNEL | product_channels, carts, cart_items |
| 11 | SYSTEM | system_settings, sequences |
| 12 | HR | departments, job_titles, employees, employee_documents |
| 13 | EXTENDED | taxes, product_taxes, product_variants, stock_adjustments, stock_adjustment_items, attachments, activity_logs, fixed_assets, bank_reconciliations, bank_reconciliation_lines |
| 14 | TRIGGERS | All business rule triggers |
