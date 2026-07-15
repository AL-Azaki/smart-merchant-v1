<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Utility function for updated_at
        DB::unprepared("
            CREATE OR REPLACE FUNCTION update_updated_at_column()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.updated_at = CURRENT_TIMESTAMP;
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        ");

        $tablesWithTimestamps = [
            'accounts', 'businesses', 'branches', 'plans', 'subscriptions', 'subscription_payments',
            'roles', 'users', 'categories', 'brands', 'units', 'products', 'product_units',
            'branch_product_prices', 'warehouses', 'inventories', 'inventory_transfers',
            'fiscal_years', 'chart_of_accounts', 'suppliers', 'purchase_invoices', 'purchase_returns',
            'customers', 'sales_invoices', 'orders', 'sales_returns', 'journal_entries', 'payments',
            'expenses', 'opening_balances', 'carts', 'system_settings', 'employees',
            'stock_adjustments', 'fixed_assets', 'bank_reconciliations'
        ];

        foreach ($tablesWithTimestamps as $table) {
            DB::unprepared("
                DROP TRIGGER IF EXISTS update_{$table}_updated_at ON {$table};
                CREATE TRIGGER update_{$table}_updated_at 
                BEFORE UPDATE ON {$table} 
                FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
            ");
        }

        // 2. System Settings & Sequences Scope Logic
        DB::unprepared("
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
        ");

        // 3. Journal Balance Check
        DB::unprepared("
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
        ");

        // 4. Sales Return QTY Validation
        DB::unprepared("
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
        ");

        // 5. Purchase Return QTY Validation
        DB::unprepared("
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
        ");

        // 6. Bank Reconciliation Match
        DB::unprepared("
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
        ");

        // 7. Stock Adjustment Logic
        DB::unprepared("
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
        ");

        // 8. Opening Balances Business Match
        DB::unprepared("
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
        ");

        // 9. Fiscal Period Overlap
        DB::unprepared("
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
        ");
    }

    public function down(): void
    {
        // Drop functions (CASCADE drops the triggers automatically)
        DB::unprepared("
            DROP FUNCTION IF EXISTS fn_fiscal_period_overlap CASCADE;
            DROP FUNCTION IF EXISTS fn_opening_bal_match CASCADE;
            DROP FUNCTION IF EXISTS fn_stock_adj_logic CASCADE;
            DROP FUNCTION IF EXISTS fn_bank_recon_match CASCADE;
            DROP FUNCTION IF EXISTS fn_purchase_return_qty CASCADE;
            DROP FUNCTION IF EXISTS fn_sales_return_qty CASCADE;
            DROP FUNCTION IF EXISTS fn_journal_balance_check CASCADE;
            DROP FUNCTION IF EXISTS fn_sequences_scope CASCADE;
            DROP FUNCTION IF EXISTS fn_system_settings_scope CASCADE;
            DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;
        ");
    }
};
