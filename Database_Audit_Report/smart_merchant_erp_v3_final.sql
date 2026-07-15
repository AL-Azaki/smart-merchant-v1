-- ======================================================================
-- Smart Merchant ERP — Database Schema v3.0 (PostgreSQL Final)
-- ======================================================================
-- Date     : 2026-07-11
-- Target   : PostgreSQL 12+
-- ======================================================================

-- ======================================================================
-- UTILITY FUNCTIONS
-- ======================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ======================================================================
-- DOMAIN 7 (Early Dependencies) — FINANCE (Currencies & Payment Terms)
-- ======================================================================
-- Moved here to satisfy Foreign Keys for Plans and Customers early on.

CREATE TABLE currencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    currency_code VARCHAR(10) NOT NULL UNIQUE,
    currency_name_ar VARCHAR(100) NOT NULL,
    currency_name_en VARCHAR(100) NOT NULL,
    currency_symbol VARCHAR(10) NOT NULL,
    decimal_places INT NOT NULL DEFAULT 2 CHECK (decimal_places BETWEEN 0 AND 6),
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    is_base_currency BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);
-- PostgreSQL Partial Unique Index for single base currency
CREATE UNIQUE INDEX uq_currencies_single_base ON currencies (is_base_currency) WHERE is_base_currency = TRUE;


-- ======================================================================
-- DOMAIN 1 — CORE
-- ======================================================================

CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    owner_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(30),
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Suspended','Closed')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    business_name VARCHAR(255) NOT NULL,
    business_type VARCHAR(100),
    primary_phone VARCHAR(30),
    primary_email VARCHAR(255),
    logo_path VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Inactive')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (account_id, id),
    UNIQUE (account_id, business_name) -- [AUDIT FIX] Added unique business name per account
);
CREATE TRIGGER update_businesses_updated_at BEFORE UPDATE ON businesses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_businesses_deleted_at ON businesses(deleted_at);

CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_name VARCHAR(255) NOT NULL,
    branch_code VARCHAR(50) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(255),
    address TEXT,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, branch_code)
);
CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON branches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- [AUDIT FIX] Ensure only one default branch per business using Partial Unique Index
CREATE UNIQUE INDEX uq_branches_single_default ON branches (business_id) WHERE is_default = TRUE;

CREATE TABLE plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_name VARCHAR(100) NOT NULL UNIQUE, -- [AUDIT FIX] Added UNIQUE
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    billing_cycle VARCHAR(50) NOT NULL CHECK (billing_cycle IN ('Monthly', 'Quarterly', 'SemiAnnual', 'Yearly')), -- [AUDIT FIX] ENUM/CHECK applied
    duration_months INT NOT NULL,
    price DECIMAL(18,2) NOT NULL CHECK (price >= 0),
    max_businesses INT NOT NULL DEFAULT 1,
    max_branches INT NOT NULL DEFAULT 1,
    max_users INT NOT NULL DEFAULT 5,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- [AUDIT FIX] Added timestamps
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (duration_months > 0 AND max_businesses > 0 AND max_branches > 0 AND max_users > 0)
);
CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    plan_id UUID NOT NULL REFERENCES plans(id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    amount_paid DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (amount_paid >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Expired','Cancelled')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (end_date >= start_date)
);
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- PostgreSQL Partial Unique Index replaces the complex MySQL `active_sentinel` trigger!
CREATE UNIQUE INDEX uq_subscriptions_active_account ON subscriptions (account_id) WHERE status = 'Active';

CREATE TABLE subscription_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE RESTRICT,
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(18,2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(100),
    reference_number VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'Paid' CHECK (status IN ('Draft','Paid','Voided')),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TRIGGER update_sub_payments_updated_at BEFORE UPDATE ON subscription_payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    role_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- [AUDIT FIX] Added updated_at
    UNIQUE (business_id, id),
    UNIQUE (business_id, role_name)
);
CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module VARCHAR(100) NOT NULL,
    permission_code VARCHAR(100) NOT NULL UNIQUE,
    permission_name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    default_branch_id UUID, -- FK will be added later
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (account_id, username)
);
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_branches (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, branch_id),
    UNIQUE (user_id, branch_id) -- Required for the users default_branch_id FK
);

-- Circular FK resolution
ALTER TABLE users 
    ADD CONSTRAINT fk_users_default_branch_assignment 
    FOREIGN KEY (id, default_branch_id) REFERENCES user_branches(user_id, branch_id) ON DELETE RESTRICT;


-- ======================================================================
-- DOMAIN 3 — CATALOG
-- ======================================================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    parent_id UUID,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    image_path VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, category_name),
    -- [AUDIT FIX] Parent Category FK is now composite to ensure same business
    FOREIGN KEY (business_id, parent_id) REFERENCES categories(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    brand_name VARCHAR(100) NOT NULL,
    description TEXT,
    logo_path VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, brand_name)
);
CREATE TRIGGER update_brands_updated_at BEFORE UPDATE ON brands FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_name VARCHAR(100) NOT NULL UNIQUE, -- [AUDIT FIX]
    unit_symbol VARCHAR(10) NOT NULL UNIQUE,
    unit_description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TRIGGER update_units_updated_at BEFORE UPDATE ON units FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    category_id UUID,
    brand_id UUID,
    product_code VARCHAR(100) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, product_code),
    FOREIGN KEY (business_id, category_id) REFERENCES categories(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, brand_id) REFERENCES brands(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE product_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL,
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE RESTRICT,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    conversion_factor DECIMAL(18,4) NOT NULL DEFAULT 1.0000 CHECK (conversion_factor > 0),
    purchase_price DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (purchase_price >= 0),
    selling_price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    minimum_price DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (minimum_price >= 0),
    is_base_unit BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, barcode),
    UNIQUE (business_id, sku),
    UNIQUE (product_id, unit_id), -- [AUDIT FIX] Prevent duplicate units per product
    FOREIGN KEY (business_id, product_id) REFERENCES products(business_id, id) ON DELETE CASCADE,
    CHECK (selling_price >= minimum_price)
);
CREATE TRIGGER update_product_units_updated_at BEFORE UPDATE ON product_units FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- [AUDIT FIX] PostgreSQL Partial Unique Index replaces the complex MySQL base_unit triggers!
CREATE UNIQUE INDEX uq_product_units_one_base ON product_units (product_id) WHERE is_base_unit = TRUE;

CREATE TABLE branch_product_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    branch_id UUID NOT NULL,
    product_unit_id UUID NOT NULL,
    purchase_price DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (purchase_price >= 0),
    selling_price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    minimum_price DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (minimum_price >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (branch_id, product_unit_id),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE CASCADE,
    CHECK (selling_price >= minimum_price)
);
CREATE TRIGGER update_branch_prices_updated_at BEFORE UPDATE ON branch_product_prices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    image_path VARCHAR(500) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- Partial index to enforce 1 primary image per product
CREATE UNIQUE INDEX uq_product_images_primary ON product_images (product_id) WHERE is_primary = TRUE;
-- ======================================================================
-- DOMAIN 4 — INVENTORY
-- ======================================================================

CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    warehouse_name VARCHAR(255) NOT NULL,
    warehouse_code VARCHAR(100) NOT NULL,
    address VARCHAR(255),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, warehouse_code),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_warehouses_updated_at BEFORE UPDATE ON warehouses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- [AUDIT FIX] Partial unique index replaces `default_branch_id` sentinel
CREATE UNIQUE INDEX uq_warehouses_default_branch ON warehouses (business_id, branch_id) WHERE is_default = TRUE;

CREATE TABLE inventories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    product_unit_id UUID NOT NULL REFERENCES product_units(id) ON DELETE RESTRICT,
    quantity DECIMAL(18,3) NOT NULL DEFAULT 0.000 CHECK (quantity >= 0),
    average_cost DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (average_cost >= 0),
    alert_quantity DECIMAL(18,3) NOT NULL DEFAULT 0.000 CHECK (alert_quantity >= 0),
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (warehouse_id, product_unit_id)
);
CREATE TRIGGER update_inventories_updated_at BEFORE UPDATE ON inventories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    product_unit_id UUID NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('In','Out','Adjust')),
    quantity DECIMAL(18,3) NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (unit_cost >= 0),
    reference_type VARCHAR(50) NOT NULL CHECK (reference_type IN ('SalesInvoice','SalesReturn','PurchaseInvoice','PurchaseReturn','Transfer','Adjustment')),
    reference_id UUID NOT NULL,
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT
);
CREATE INDEX idx_inv_tx_reference ON inventory_transactions (reference_type, reference_id);

CREATE TABLE inventory_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    from_warehouse_id UUID NOT NULL,
    to_warehouse_id UUID NOT NULL,
    transfer_number VARCHAR(50) NOT NULL,
    transfer_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Completed','Cancelled')),
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, transfer_number),
    FOREIGN KEY (business_id, from_warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, to_warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT,
    CHECK (from_warehouse_id <> to_warehouse_id)
);
CREATE TRIGGER update_inventory_transfers_updated_at BEFORE UPDATE ON inventory_transfers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE inventory_transfer_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    transfer_id UUID NOT NULL,
    product_unit_id UUID NOT NULL,
    quantity DECIMAL(18,3) NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (unit_cost >= 0),
    UNIQUE (transfer_id, product_unit_id), -- [AUDIT FIX] Prevents duplicate products in transfer
    FOREIGN KEY (business_id, transfer_id) REFERENCES inventory_transfers(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT
);


-- ======================================================================
-- DOMAIN 7 — FINANCE (Part 1: COA & Master Data)
-- ======================================================================

CREATE TABLE fiscal_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    fiscal_year_code VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Open' CHECK (status IN ('Open','Closed')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, fiscal_year_code),
    CHECK (end_date >= start_date)
);
CREATE TRIGGER update_fiscal_years_updated_at BEFORE UPDATE ON fiscal_years FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE fiscal_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    fiscal_year_id UUID NOT NULL,
    period_number INT NOT NULL CHECK (period_number BETWEEN 1 AND 12),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Open' CHECK (status IN ('Open','Closed')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (fiscal_year_id, period_number),
    FOREIGN KEY (business_id, fiscal_year_id) REFERENCES fiscal_years(business_id, id) ON DELETE RESTRICT,
    CHECK (end_date >= start_date)
);

CREATE TABLE chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    parent_account_id UUID,
    currency_id UUID REFERENCES currencies(id) ON DELETE RESTRICT,
    account_code VARCHAR(50) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('Asset','Liability','Equity','Revenue','Expense')),
    account_category VARCHAR(100),
    normal_balance VARCHAR(10) NOT NULL CHECK (normal_balance IN ('Debit','Credit')),
    account_level INT NOT NULL DEFAULT 1 CHECK (account_level > 0),
    allow_posting BOOLEAN NOT NULL DEFAULT FALSE,
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, account_code),
    -- [AUDIT FIX] Composite FK ensures parent belongs to same business
    FOREIGN KEY (business_id, parent_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT,
    -- [AUDIT FIX] Ensure normal balance matches accounting rules
    CHECK (
        (account_type IN ('Asset','Expense') AND normal_balance = 'Debit') OR
        (account_type IN ('Liability','Equity','Revenue') AND normal_balance = 'Credit')
    )
);
CREATE TRIGGER update_coa_updated_at BEFORE UPDATE ON chart_of_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE payment_terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    term_name VARCHAR(100) NOT NULL,
    days_to_due INT NOT NULL DEFAULT 0 CHECK (days_to_due >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, term_name)
);

CREATE TABLE payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    chart_of_account_id UUID NOT NULL,
    method_code VARCHAR(30) NOT NULL,
    method_name VARCHAR(100) NOT NULL,
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('Cash','Bank','Card','DigitalWallet','Other')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (business_id, id),
    UNIQUE (business_id, method_code),
    FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT
);


-- ======================================================================
-- DOMAIN 6 — PURCHASING
-- ======================================================================

CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    supplier_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    phone VARCHAR(30),
    supplier_address VARCHAR(255),
    default_currency_id UUID REFERENCES currencies(id) ON DELETE SET NULL,
    payment_term_id UUID,
    payable_account_id UUID,
    credit_limit DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (credit_limit >= 0), -- [AUDIT FIX] Nullability matches customers
    opening_balance DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (opening_balance >= 0),
    opening_balance_type VARCHAR(10) CHECK (opening_balance_type IN ('debit','credit')),
    opening_balance_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    FOREIGN KEY (business_id, payment_term_id) REFERENCES payment_terms(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, payable_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT,
    -- [AUDIT FIX] Force type if balance > 0
    CHECK (opening_balance = 0 OR opening_balance_type IS NOT NULL)
);
CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE purchase_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    supplier_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    invoice_number VARCHAR(50) NOT NULL,
    purchase_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    sub_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    discount_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    tax_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    grand_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_sub_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_discount_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_tax_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_grand_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'Unpaid' CHECK (payment_status IN ('Unpaid','Partial','Paid')), -- [AUDIT FIX] Added payment_status
    status VARCHAR(20) NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Posted','Cancelled')),
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, invoice_number),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, supplier_id) REFERENCES suppliers(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT,
    CHECK (due_date IS NULL OR due_date >= purchase_date),
    CHECK (sub_total >= 0 AND discount_total >= 0 AND tax_total >= 0 AND grand_total >= 0),
    CHECK (base_sub_total >= 0 AND base_discount_total >= 0 AND base_tax_total >= 0 AND base_grand_total >= 0)
);
CREATE TRIGGER update_purchase_invoices_updated_at BEFORE UPDATE ON purchase_invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE purchase_invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    purchase_invoice_id UUID NOT NULL,
    product_unit_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    quantity DECIMAL(18,3) NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(18,2) NOT NULL CHECK (unit_price >= 0),
    discount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (discount >= 0),
    tax DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (tax >= 0),
    line_total DECIMAL(18,2) NOT NULL CHECK (line_total >= 0),
    base_line_total DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_line_total >= 0),
    UNIQUE (business_id, id),
    FOREIGN KEY (business_id, purchase_invoice_id) REFERENCES purchase_invoices(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT
);

CREATE TABLE purchase_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    purchase_invoice_id UUID NOT NULL,
    return_number VARCHAR(50) NOT NULL,
    return_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    base_total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_total_amount >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Posted','Cancelled')),
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, return_number),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, purchase_invoice_id) REFERENCES purchase_invoices(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_purchase_returns_updated_at BEFORE UPDATE ON purchase_returns FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE purchase_return_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    purchase_return_id UUID NOT NULL,
    purchase_invoice_item_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    quantity DECIMAL(18,3) NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(18,2) NOT NULL CHECK (unit_price >= 0),
    line_total DECIMAL(18,2) NOT NULL CHECK (line_total >= 0),
    base_line_total DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_line_total >= 0),
    UNIQUE (business_id, id),
    FOREIGN KEY (business_id, purchase_return_id) REFERENCES purchase_returns(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (purchase_invoice_item_id) REFERENCES purchase_invoice_items(id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT
);
-- ======================================================================
-- DOMAIN 5 — SALES
-- ======================================================================

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    customer_name VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(255),
    address TEXT,
    credit_limit DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (credit_limit >= 0),
    default_currency_id UUID REFERENCES currencies(id) ON DELETE SET NULL,
    payment_term_id UUID,
    receivable_account_id UUID,
    opening_balance DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (opening_balance >= 0),
    opening_balance_type VARCHAR(10) CHECK (opening_balance_type IN ('debit','credit')),
    opening_balance_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    FOREIGN KEY (business_id, payment_term_id) REFERENCES payment_terms(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, receivable_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT,
    -- [AUDIT FIX] Ensure type is present if balance exists
    CHECK (opening_balance = 0 OR opening_balance_type IS NOT NULL)
);
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    channel_name VARCHAR(100) NOT NULL,
    channel_code VARCHAR(50) NOT NULL,
    channel_type VARCHAR(50) NOT NULL CHECK (channel_type IN ('POS','Ecommerce','B2B','Marketplace','Other')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (business_id, id),
    UNIQUE (business_id, channel_code)
);

CREATE TABLE sales_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    customer_id UUID, -- NULL for walk-in customers
    invoice_number VARCHAR(50) NOT NULL,
    invoice_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    sub_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    discount_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    tax_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    grand_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_sub_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_discount_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_tax_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_grand_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'Unpaid' CHECK (payment_status IN ('Unpaid','Partial','Paid')),
    status VARCHAR(20) NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Posted','Cancelled')),
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, invoice_number),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, customer_id) REFERENCES customers(business_id, id) ON DELETE RESTRICT,
    CHECK (due_date IS NULL OR due_date >= invoice_date),
    CHECK (sub_total >= 0 AND discount_total >= 0 AND tax_total >= 0 AND grand_total >= 0),
    CHECK (base_sub_total >= 0 AND base_discount_total >= 0 AND base_tax_total >= 0 AND base_grand_total >= 0)
);
CREATE TRIGGER update_sales_invoices_updated_at BEFORE UPDATE ON sales_invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_sales_invoices_status ON sales_invoices(status, payment_status);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    channel_id UUID NOT NULL,
    customer_id UUID,
    order_number VARCHAR(50) NOT NULL,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    sub_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    discount_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    tax_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    grand_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_sub_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_discount_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_tax_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    base_grand_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'Unpaid' CHECK (payment_status IN ('Unpaid','Partial','Paid')),
    status VARCHAR(30) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Confirmed','Processing','Ready','Shipped','Delivered','Cancelled')),
    notes TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, order_number),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, channel_id) REFERENCES channels(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, customer_id) REFERENCES customers(business_id, id) ON DELETE RESTRICT,
    CHECK (sub_total >= 0 AND discount_total >= 0 AND tax_total >= 0 AND grand_total >= 0),
    CHECK (base_sub_total >= 0 AND base_discount_total >= 0 AND base_tax_total >= 0 AND base_grand_total >= 0)
);
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    order_id UUID NOT NULL,
    product_unit_id UUID NOT NULL,
    quantity DECIMAL(18,3) NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(18,2) NOT NULL CHECK (unit_price >= 0),
    discount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (discount >= 0),
    tax DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (tax >= 0),
    line_total DECIMAL(18,2) NOT NULL CHECK (line_total >= 0),
    base_line_total DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_line_total >= 0),
    UNIQUE (business_id, id),
    FOREIGN KEY (business_id, order_id) REFERENCES orders(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT
);

CREATE TABLE sales_invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    sales_invoice_id UUID NOT NULL,
    order_item_id UUID, -- Optional link to original order
    product_unit_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    quantity DECIMAL(18,3) NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(18,2) NOT NULL CHECK (unit_price >= 0),
    cost_price DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (cost_price >= 0),
    discount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (discount >= 0),
    tax DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (tax >= 0),
    line_total DECIMAL(18,2) NOT NULL CHECK (line_total >= 0),
    cost_total DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (cost_total >= 0),
    base_line_total DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_line_total >= 0),
    UNIQUE (business_id, id),
    FOREIGN KEY (business_id, sales_invoice_id) REFERENCES sales_invoices(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (order_item_id) REFERENCES order_items(id) ON DELETE SET NULL,
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT
);

CREATE TABLE sales_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    sales_invoice_id UUID NOT NULL,
    return_number VARCHAR(50) NOT NULL,
    return_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    base_total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_total_amount >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Posted','Cancelled')),
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, return_number),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, sales_invoice_id) REFERENCES sales_invoices(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_sales_returns_updated_at BEFORE UPDATE ON sales_returns FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE sales_return_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    sales_return_id UUID NOT NULL,
    sales_invoice_item_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    quantity DECIMAL(18,3) NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(18,2) NOT NULL CHECK (unit_price >= 0),
    cost_price DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (cost_price >= 0),
    total_price DECIMAL(18,2) NOT NULL CHECK (total_price >= 0),
    cost_total DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (cost_total >= 0),
    base_total_price DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_total_price >= 0),
    UNIQUE (business_id, id),
    FOREIGN KEY (business_id, sales_return_id) REFERENCES sales_returns(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (sales_invoice_item_id) REFERENCES sales_invoice_items(id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT
);
-- ======================================================================
-- DOMAIN 7 — FINANCE (Part 2: Transactions)
-- ======================================================================

CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    fiscal_year_id UUID NOT NULL,
    fiscal_period_id UUID NOT NULL,
    journal_number VARCHAR(50) NOT NULL,
    journal_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_type VARCHAR(50) NOT NULL CHECK (reference_type IN ('SalesInvoice','SalesReturn','PurchaseInvoice','PurchaseReturn','Payment','Expense','Manual','StockAdjustment','ClosingEntry')),
    reference_id UUID NOT NULL,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Posted','Reversed')),
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, journal_number),
    FOREIGN KEY (business_id, fiscal_year_id) REFERENCES fiscal_years(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, fiscal_period_id) REFERENCES fiscal_periods(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_journal_entries_updated_at BEFORE UPDATE ON journal_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_je_reference ON journal_entries (reference_type, reference_id);

CREATE TABLE journal_entry_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    journal_entry_id UUID NOT NULL,
    line_number INT NOT NULL,
    chart_of_account_id UUID NOT NULL,
    description TEXT,
    line_currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    line_exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (line_exchange_rate > 0),
    debit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (debit_amount >= 0),
    credit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (credit_amount >= 0),
    base_debit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_debit_amount >= 0),
    base_credit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_credit_amount >= 0),
    UNIQUE (journal_entry_id, line_number),
    FOREIGN KEY (business_id, journal_entry_id) REFERENCES journal_entries(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT,
    -- XOR check for single side entry
    CHECK (
        (debit_amount > 0 AND credit_amount = 0) OR
        (debit_amount = 0 AND credit_amount > 0) OR
        (debit_amount = 0 AND credit_amount = 0)
    ),
    CHECK (
        (base_debit_amount > 0 AND base_credit_amount = 0) OR
        (base_debit_amount = 0 AND base_credit_amount > 0) OR
        (base_debit_amount = 0 AND base_credit_amount = 0)
    )
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    payment_number VARCHAR(50) NOT NULL,
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method_id UUID NOT NULL,
    chart_of_account_id UUID NOT NULL,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    amount DECIMAL(18,2) NOT NULL CHECK (amount > 0),
    base_amount DECIMAL(18,2) NOT NULL CHECK (base_amount > 0),
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('Receipt','Payment','Refund','Adjustment','Transfer')),
    reference_type VARCHAR(50) NOT NULL CHECK (reference_type IN ('SalesInvoice','PurchaseInvoice','SalesReturn','PurchaseReturn','Expense','Transfer','OpeningBalance')),
    reference_id UUID NOT NULL,
    contact_type VARCHAR(20) CHECK (contact_type IN ('Customer','Supplier','Employee','Other')),
    contact_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'Posted' CHECK (status IN ('Draft','Posted','Cancelled')),
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, payment_number),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, payment_method_id) REFERENCES payment_methods(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE INDEX idx_payments_reference ON payments(reference_type, reference_id);

CREATE TABLE expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    chart_of_account_id UUID NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (business_id, id),
    UNIQUE (business_id, category_name),
    FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT
);

CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    expense_category_id UUID NOT NULL,
    expense_number VARCHAR(50) NOT NULL,
    expense_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method_id UUID NOT NULL,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    amount DECIMAL(18,2) NOT NULL CHECK (amount > 0),
    base_amount DECIMAL(18,2) NOT NULL CHECK (base_amount > 0),
    tax_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    reference_number VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Posted','Cancelled')),
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, expense_number),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, expense_category_id) REFERENCES expense_categories(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, payment_method_id) REFERENCES payment_methods(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE opening_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    fiscal_year_id UUID NOT NULL,
    chart_of_account_id UUID NOT NULL,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000 CHECK (exchange_rate > 0),
    debit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (debit_amount >= 0),
    credit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (credit_amount >= 0),
    base_debit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_debit_amount >= 0),
    base_credit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_credit_amount >= 0),
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (fiscal_year_id, chart_of_account_id),
    FOREIGN KEY (business_id, fiscal_year_id) REFERENCES fiscal_years(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT,
    CHECK (
        (debit_amount >= 0 AND credit_amount = 0) OR
        (debit_amount = 0 AND credit_amount >= 0)
    ),
    CHECK (
        (base_debit_amount >= 0 AND base_credit_amount = 0) OR
        (base_debit_amount = 0 AND base_credit_amount >= 0)
    )
);
CREATE TRIGGER update_opening_balances_updated_at BEFORE UPDATE ON opening_balances FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- ======================================================================
-- DOMAIN 8 — SALES CHANNEL
-- ======================================================================

CREATE TABLE product_channels (
    business_id UUID NOT NULL,
    product_unit_id UUID NOT NULL,
    channel_id UUID NOT NULL,
    sale_price DECIMAL(18,2) NOT NULL CHECK (sale_price >= 0),
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INT NOT NULL DEFAULT 0,
    PRIMARY KEY (business_id, product_unit_id, channel_id),
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, channel_id) REFERENCES channels(business_id, id) ON DELETE CASCADE
);

CREATE TABLE carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    channel_id UUID NOT NULL,
    customer_id UUID,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Converted','Abandoned')),
    sub_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    tax_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    grand_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id, channel_id) REFERENCES channels(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, customer_id) REFERENCES customers(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_carts_updated_at BEFORE UPDATE ON carts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- Partial Unique Index replaces active_customer_id sentinel trigger!
CREATE UNIQUE INDEX uq_carts_active_customer ON carts (business_id, customer_id) WHERE status = 'Active';

CREATE TABLE cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    cart_id UUID NOT NULL,
    product_unit_id UUID NOT NULL,
    quantity DECIMAL(18,3) NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(18,2) NOT NULL CHECK (unit_price >= 0),
    tax DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (tax >= 0),
    line_total DECIMAL(18,2) NOT NULL CHECK (line_total >= 0),
    base_line_total DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_line_total >= 0),
    FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT
);

-- ======================================================================
-- DOMAIN 9 — SYSTEM
-- ======================================================================

CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    scope_business_id VARCHAR(50) NOT NULL, -- UUID string or '__GLOBAL__'
    setting_group VARCHAR(50) NOT NULL,
    setting_key VARCHAR(100) NOT NULL,
    setting_value JSONB,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (scope_business_id, setting_key)
);
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE sequences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    branch_scope_id VARCHAR(50) NOT NULL, -- UUID string or '__GLOBAL__'
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('SalesInvoice','PurchaseInvoice','SalesReturn','PurchaseReturn','SalesOrder','PurchaseOrder','Payment','JournalEntry','Transfer')),
    prefix VARCHAR(20),
    next_number BIGINT NOT NULL DEFAULT 1 CHECK (next_number > 0),
    padding INT NOT NULL DEFAULT 5,
    UNIQUE (business_id, branch_scope_id, document_type)
);

-- ======================================================================
-- DOMAIN 10 — HR & EMPLOYEES
-- ======================================================================

CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    department_name VARCHAR(100) NOT NULL,
    manager_id UUID, -- Will be self-referenced to employees if needed
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (business_id, id),
    UNIQUE (business_id, department_name)
);

CREATE TABLE job_titles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    title_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (business_id, id),
    UNIQUE (business_id, title_name)
);

CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    department_id UUID NOT NULL,
    job_title_id UUID NOT NULL,
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL,
    employee_code VARCHAR(50) NOT NULL, -- [AUDIT FIX] Added code
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(30),
    hire_date DATE NOT NULL,
    base_salary DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (base_salary >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','OnLeave','Terminated')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, employee_code),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, department_id) REFERENCES departments(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, job_title_id) REFERENCES job_titles(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE employee_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    document_path VARCHAR(500) NOT NULL,
    upload_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================
-- DOMAIN 11 — EXTENDED FEATURES
-- ======================================================================

CREATE TABLE taxes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    tax_name VARCHAR(100) NOT NULL,
    tax_rate DECIMAL(5,2) NOT NULL CHECK (tax_rate >= 0 AND tax_rate <= 100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (business_id, id),
    UNIQUE (business_id, tax_name)
);

CREATE TABLE product_taxes (
    business_id UUID NOT NULL,
    product_unit_id UUID NOT NULL,
    tax_id UUID NOT NULL,
    PRIMARY KEY (business_id, product_unit_id, tax_id),
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, tax_id) REFERENCES taxes(business_id, id) ON DELETE CASCADE
);

CREATE TABLE product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE, -- [AUDIT FIX] Added business_id
    product_unit_id UUID NOT NULL,
    variant_name VARCHAR(100) NOT NULL,
    variant_value VARCHAR(100) NOT NULL,
    UNIQUE (product_unit_id, variant_name),
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE CASCADE
);

CREATE TABLE stock_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    warehouse_id UUID NOT NULL,
    adjustment_number VARCHAR(50) NOT NULL,
    adjustment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    adjustment_type VARCHAR(20) NOT NULL CHECK (adjustment_type IN ('Increase','Decrease','Damage','Loss')),
    status VARCHAR(20) NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Posted')),
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, adjustment_number),
    FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_stock_adjustments_updated_at BEFORE UPDATE ON stock_adjustments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE stock_adjustment_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    adjustment_id UUID NOT NULL,
    product_unit_id UUID NOT NULL,
    system_qty DECIMAL(18,3) NOT NULL,
    physical_qty DECIMAL(18,3) NOT NULL,
    diff_qty DECIMAL(18,3) NOT NULL,
    FOREIGN KEY (business_id, adjustment_id) REFERENCES stock_adjustments(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT,
    CHECK (diff_qty = physical_qty - system_qty)
);

CREATE TABLE attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    upload_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_attachments_entity ON attachments (business_id, entity_type, entity_id);

CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_activity_logs_lookup ON activity_logs (business_id, entity_type, entity_id);

CREATE TABLE fixed_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL,
    asset_account_id UUID NOT NULL, -- [AUDIT FIX] Link to COA
    depreciation_account_id UUID NOT NULL, -- [AUDIT FIX] Link to COA
    asset_name VARCHAR(255) NOT NULL,
    asset_code VARCHAR(50) NOT NULL,
    purchase_date DATE NOT NULL,
    currency_id UUID NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT,
    exchange_rate DECIMAL(18,8) NOT NULL DEFAULT 1.00000000,
    purchase_price DECIMAL(18,2) NOT NULL CHECK (purchase_price >= 0),
    base_purchase_price DECIMAL(18,2) NOT NULL CHECK (base_purchase_price >= 0),
    current_value DECIMAL(18,2) NOT NULL CHECK (current_value >= 0),
    base_current_value DECIMAL(18,2) NOT NULL CHECK (base_current_value >= 0),
    depreciation_rate DECIMAL(5,2) NOT NULL CHECK (depreciation_rate >= 0 AND depreciation_rate <= 100),
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Disposed','Depreciated')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE (business_id, asset_code),
    FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, asset_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT,
    FOREIGN KEY (business_id, depreciation_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_fixed_assets_updated_at BEFORE UPDATE ON fixed_assets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE bank_reconciliations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT,
    chart_of_account_id UUID NOT NULL,
    statement_date DATE NOT NULL,
    statement_balance DECIMAL(18,2) NOT NULL,
    system_balance DECIMAL(18,2) NOT NULL,
    difference DECIMAL(18,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Completed')),
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (business_id, id),
    UNIQUE (business_id, chart_of_account_id, statement_date),
    FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT
);
CREATE TRIGGER update_bank_reconciliations_updated_at BEFORE UPDATE ON bank_reconciliations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE bank_reconciliation_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    bank_reconciliation_id UUID NOT NULL,
    payment_id UUID NOT NULL,
    is_cleared BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (business_id, bank_reconciliation_id) REFERENCES bank_reconciliations(business_id, id) ON DELETE CASCADE,
    FOREIGN KEY (business_id, payment_id) REFERENCES payments(business_id, id) ON DELETE RESTRICT
);

-- ======================================================================
-- POSTGRESQL TRIGGERS (BUSINESS RULES)
-- ======================================================================

-- Scope logic for system settings & sequences
CREATE OR REPLACE FUNCTION fn_system_settings_scope() RETURNS TRIGGER AS $$
BEGIN
    NEW.scope_business_id := COALESCE(NEW.business_id::TEXT, '__GLOBAL__');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_system_settings_scope BEFORE INSERT OR UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION fn_system_settings_scope();

CREATE OR REPLACE FUNCTION fn_sequences_scope() RETURNS TRIGGER AS $$
BEGIN
    NEW.branch_scope_id := COALESCE(NEW.branch_id::TEXT, '__GLOBAL__');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_sequences_scope BEFORE INSERT OR UPDATE ON sequences FOR EACH ROW EXECUTE FUNCTION fn_sequences_scope();


-- Journal balance check
CREATE OR REPLACE FUNCTION fn_journal_balance_check() RETURNS TRIGGER AS $$
DECLARE
    v_debit DECIMAL(18,2);
    v_credit DECIMAL(18,2);
BEGIN
    IF NEW.status = 'Posted' AND OLD.status <> 'Posted' THEN
        SELECT COALESCE(SUM(base_debit_amount),0), COALESCE(SUM(base_credit_amount),0)
        INTO v_debit, v_credit
        FROM journal_entry_lines
        WHERE journal_entry_id = NEW.id;

        IF v_debit = 0 OR v_credit = 0 OR v_debit <> v_credit THEN
            RAISE EXCEPTION 'Journal entry cannot be posted unless base debits equal base credits.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_journal_balance_check BEFORE UPDATE ON journal_entries FOR EACH ROW EXECUTE FUNCTION fn_journal_balance_check();


-- Sales Return QTY validation
CREATE OR REPLACE FUNCTION fn_sales_return_qty() RETURNS TRIGGER AS $$
DECLARE
    v_invoiced_qty DECIMAL(18,3);
    v_returned_qty DECIMAL(18,3);
BEGIN
    SELECT quantity INTO v_invoiced_qty FROM sales_invoice_items WHERE id = NEW.sales_invoice_item_id;
    
    SELECT COALESCE(SUM(quantity), 0) INTO v_returned_qty 
    FROM sales_return_items 
    WHERE sales_invoice_item_id = NEW.sales_invoice_item_id 
      AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID);

    IF (v_returned_qty + NEW.quantity) > v_invoiced_qty THEN
        RAISE EXCEPTION 'Returned quantity exceeds invoiced quantity.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_sales_return_qty BEFORE INSERT OR UPDATE ON sales_return_items FOR EACH ROW EXECUTE FUNCTION fn_sales_return_qty();


-- Purchase Return QTY validation
CREATE OR REPLACE FUNCTION fn_purchase_return_qty() RETURNS TRIGGER AS $$
DECLARE
    v_invoiced_qty DECIMAL(18,3);
    v_returned_qty DECIMAL(18,3);
BEGIN
    SELECT quantity INTO v_invoiced_qty FROM purchase_invoice_items WHERE id = NEW.purchase_invoice_item_id;
    
    SELECT COALESCE(SUM(quantity), 0) INTO v_returned_qty 
    FROM purchase_return_items 
    WHERE purchase_invoice_item_id = NEW.purchase_invoice_item_id 
      AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID);

    IF (v_returned_qty + NEW.quantity) > v_invoiced_qty THEN
        RAISE EXCEPTION 'Returned quantity exceeds purchased quantity.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_purchase_return_qty BEFORE INSERT OR UPDATE ON purchase_return_items FOR EACH ROW EXECUTE FUNCTION fn_purchase_return_qty();


-- Bank Reconciliation Payment Match
CREATE OR REPLACE FUNCTION fn_bank_recon_match() RETURNS TRIGGER AS $$
DECLARE
    v_recon_coa UUID;
    v_payment_coa UUID;
    v_recon_currency UUID;
    v_payment_currency UUID;
BEGIN
    SELECT chart_of_account_id INTO v_recon_coa FROM bank_reconciliations WHERE id = NEW.bank_reconciliation_id;
    SELECT chart_of_account_id, currency_id INTO v_payment_coa, v_payment_currency FROM payments WHERE id = NEW.payment_id;
    SELECT currency_id INTO v_recon_currency FROM chart_of_accounts WHERE id = v_recon_coa;

    IF v_recon_coa <> v_payment_coa THEN
        RAISE EXCEPTION 'Payment account does not match the bank reconciliation account.';
    END IF;
    IF v_recon_currency IS NOT NULL AND v_payment_currency <> v_recon_currency THEN
        RAISE EXCEPTION 'Payment currency does not match the reconciled bank account currency.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_bank_recon_match BEFORE INSERT OR UPDATE ON bank_reconciliation_lines FOR EACH ROW EXECUTE FUNCTION fn_bank_recon_match();


-- Stock Adjustment Logic Validation
CREATE OR REPLACE FUNCTION fn_stock_adj_logic() RETURNS TRIGGER AS $$
DECLARE
    v_type VARCHAR(20);
BEGIN
    SELECT adjustment_type INTO v_type FROM stock_adjustments WHERE id = NEW.adjustment_id;
    IF (v_type = 'Increase' AND NEW.diff_qty <= 0) OR (v_type IN ('Decrease','Damage','Loss') AND NEW.diff_qty >= 0) THEN
        RAISE EXCEPTION 'Stock adjustment item sign does not match the adjustment type.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_stock_adj_logic BEFORE INSERT OR UPDATE ON stock_adjustment_items FOR EACH ROW EXECUTE FUNCTION fn_stock_adj_logic();


-- Opening Balances Business Match
CREATE OR REPLACE FUNCTION fn_opening_bal_match() RETURNS TRIGGER AS $$
DECLARE
    v_year_business UUID;
    v_coa_business UUID;
BEGIN
    SELECT business_id INTO v_year_business FROM fiscal_years WHERE id = NEW.fiscal_year_id;
    SELECT business_id INTO v_coa_business FROM chart_of_accounts WHERE id = NEW.chart_of_account_id;
    IF v_year_business <> v_coa_business THEN
        RAISE EXCEPTION 'Opening balance fiscal year and chart of account must belong to the same business.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_opening_bal_match BEFORE INSERT OR UPDATE ON opening_balances FOR EACH ROW EXECUTE FUNCTION fn_opening_bal_match();


-- Fiscal Period Overlap Prevention
CREATE OR REPLACE FUNCTION fn_fiscal_period_overlap() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM fiscal_periods 
        WHERE fiscal_year_id = NEW.fiscal_year_id 
          AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
          AND NOT (NEW.end_date < start_date OR NEW.start_date > end_date)
    ) THEN
        RAISE EXCEPTION 'Fiscal period dates overlap with an existing period in the same fiscal year.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_fiscal_period_overlap BEFORE INSERT OR UPDATE ON fiscal_periods FOR EACH ROW EXECUTE FUNCTION fn_fiscal_period_overlap();

-- ======================================================================
-- END OF SCHEMA v3.0
-- ======================================================================
