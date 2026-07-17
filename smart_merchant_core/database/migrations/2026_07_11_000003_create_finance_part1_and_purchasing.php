<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // ==========================================
        // DOMAIN 7 - FINANCE (Part 1)
        // ==========================================
        Schema::create('fiscal_years', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->string('fiscal_year_code', 20);
            $table->string('fiscal_year_name', 100);
            $table->text('description')->nullable();
            $table->date('start_date');
            $table->date('end_date');
            $table->string('status', 20)->default('Open');
            $table->timestamps();
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'fiscal_year_code']);
        });
        DB::statement("ALTER TABLE fiscal_years ADD CONSTRAINT chk_fy_status CHECK (status IN ('Open','Closed'))");
        DB::statement("ALTER TABLE fiscal_years ADD CONSTRAINT chk_fy_dates CHECK (end_date > start_date)");

        Schema::create('fiscal_periods', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('fiscal_year_id');
            $table->integer('period_number');
            $table->string('period_name', 100);
            $table->date('start_date');
            $table->date('end_date');
            $table->string('status', 20)->default('Open');
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['fiscal_year_id', 'period_number']);
            $table->foreign(['business_id', 'fiscal_year_id'])->references(['business_id', 'id'])->on('fiscal_years')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE fiscal_periods ADD CONSTRAINT chk_fp_status CHECK (status IN ('Open','Closed'))");
        DB::statement("ALTER TABLE fiscal_periods ADD CONSTRAINT chk_fp_period CHECK (period_number BETWEEN 1 AND 12)");
        DB::statement("ALTER TABLE fiscal_periods ADD CONSTRAINT chk_fp_dates CHECK (end_date > start_date)");

        Schema::create('exchange_rates', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->foreignUuid('source_currency_id')->constrained('currencies')->restrictOnDelete();
            $table->foreignUuid('target_currency_id')->constrained('currencies')->restrictOnDelete();
            $table->date('effective_date');
            $table->decimal('rate', 20, 8);
            $table->timestamps();

            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'source_currency_id', 'target_currency_id', 'effective_date'], 'uq_exchange_rates_date');
        });
        DB::statement("ALTER TABLE exchange_rates ADD CONSTRAINT chk_er_diff_currencies CHECK (source_currency_id != target_currency_id)");
        DB::statement("ALTER TABLE exchange_rates ADD CONSTRAINT chk_er_rate_positive CHECK (rate > 0)");

        Schema::create('chart_of_accounts', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('parent_account_id')->nullable();
            $table->foreignUuid('currency_id')->nullable()->constrained('currencies')->restrictOnDelete();
            $table->string('account_code', 50);
            $table->string('account_name', 255);
            $table->text('description')->nullable();
            $table->foreignId('account_type_id')->constrained('account_types')->restrictOnDelete();
            $table->string('account_category', 100)->nullable();
            $table->string('normal_balance', 10);
            $table->integer('account_level')->default(1);
            $table->boolean('allow_posting')->default(false);
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'account_code']);
            $table->foreign(['business_id', 'parent_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE chart_of_accounts ADD CONSTRAINT chk_coa_balance CHECK (normal_balance IN ('Debit','Credit'))");
        DB::statement("ALTER TABLE chart_of_accounts ADD CONSTRAINT chk_coa_level CHECK (account_level > 0)");
        // DB::statement("ALTER TABLE chart_of_accounts ADD CONSTRAINT chk_coa_consistency CHECK ((account_type IN ('Asset','Expense') AND normal_balance = 'Debit') OR (account_type IN ('Liability','Equity','Revenue') AND normal_balance = 'Credit'))");

        Schema::create('payment_terms', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->string('term_name', 100);
            $table->integer('days_to_due')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'term_name']);
        });
        DB::statement("ALTER TABLE payment_terms ADD CONSTRAINT chk_pt_days CHECK (days_to_due >= 0)");

        Schema::create('payment_methods', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('chart_of_account_id');
            $table->string('method_code', 30);
            $table->string('method_name', 100);
            $table->string('payment_type', 20);
            $table->boolean('is_active')->default(true);
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'method_code']);
            $table->foreign(['business_id', 'chart_of_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE payment_methods ADD CONSTRAINT chk_pm_type CHECK (payment_type IN ('Cash','Bank','Card','DigitalWallet','Other'))");

        Schema::create('cash_registers', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->uuid('branch_id');
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->string('register_name', 100);
            $table->string('status', 20)->default('Closed');
            $table->decimal('current_balance', 15, 4)->default(0);
            $table->foreignUuid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'register_name']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE cash_registers ADD CONSTRAINT chk_cr_status CHECK (status IN ('Open', 'Closed'))");

        Schema::create('cash_transactions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->foreignUuid('cash_register_id')->constrained('cash_registers')->cascadeOnDelete();
            $table->string('transaction_type', 30);
            $table->decimal('amount', 15, 4);
            $table->string('document_type', 100)->nullable();
            $table->uuid('document_id')->nullable();
            $table->text('notes')->nullable();
            $table->uuid('reference_id')->nullable();
            $table->foreignUuid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent();
            
            $table->unique(['business_id', 'id']);
        });
        Schema::table('cash_transactions', function (Blueprint $table) {
            $table->foreign('reference_id')->references('id')->on('cash_transactions')->nullOnDelete();
        });
        DB::statement("ALTER TABLE cash_transactions ADD CONSTRAINT chk_ct_type CHECK (transaction_type IN ('Deposit', 'Withdrawal', 'Transfer In', 'Transfer Out', 'Adjustment', 'Payment', 'Receipt'))");
        DB::statement("ALTER TABLE cash_transactions ADD CONSTRAINT chk_ct_amount CHECK (amount > 0)");

        Schema::create('bank_accounts', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->uuid('branch_id')->nullable();
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->string('account_number', 50);
            $table->string('iban', 50)->nullable();
            $table->string('bank_name', 100);
            $table->string('display_name', 100)->nullable();
            $table->text('description')->nullable();
            $table->string('status', 20)->default('Active'); // Active, Frozen, Closed
            $table->boolean('is_default')->default(false);
            
            $table->decimal('opening_balance', 18, 4)->default(0.0000);
            $table->date('opening_balance_date')->nullable();
            $table->decimal('current_balance', 18, 4)->default(0.0000);
            $table->decimal('last_reconciled_balance', 18, 4)->nullable();
            $table->timestamp('last_reconciled_at')->nullable();
            
            $table->foreignUuid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'account_number']);
            $table->unique(['business_id', 'iban']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
        });

        DB::statement("ALTER TABLE bank_accounts ADD CONSTRAINT chk_ba_status CHECK (status IN ('Active', 'Frozen', 'Closed'))");

        Schema::create('bank_transactions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('bank_account_id');
            
            $table->string('transaction_type', 50); // Deposit, Withdrawal, Transfer In, Transfer Out, Adjustment, Bank Fee, Interest, Opening Balance
            $table->string('direction', 10); // Credit, Debit
            $table->decimal('amount', 18, 4); // Must be > 0
            
            $table->decimal('foreign_currency_amount', 18, 4)->nullable();
            $table->string('foreign_currency_code', 3)->nullable();
            $table->decimal('exchange_rate', 18, 6)->nullable();
            
            // Financial Document Policy
            $table->string('document_type')->nullable();
            $table->uuid('document_id')->nullable();
            
            $table->uuid('bank_transfer_id')->nullable();
            $table->string('reconciliation_status', 30)->default('Unreconciled'); // Unreconciled, Reconciled
            $table->text('notes')->nullable();
            
            $table->foreignUuid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps(); // includes created_at, updated_at
            
            // Relationships & Constraints
            $table->unique(['business_id', 'id']);
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            $table->foreign(['business_id', 'bank_account_id'])->references(['business_id', 'id'])->on('bank_accounts')->cascadeOnDelete();
            
            $table->index(['document_type', 'document_id']);
        });

        DB::statement("ALTER TABLE bank_transactions ADD CONSTRAINT chk_bt_type CHECK (transaction_type IN ('Deposit', 'Withdrawal', 'Transfer In', 'Transfer Out', 'Adjustment', 'Bank Fee', 'Interest', 'Opening Balance'))");
        DB::statement("ALTER TABLE bank_transactions ADD CONSTRAINT chk_bt_direction CHECK (direction IN ('Credit', 'Debit'))");
        DB::statement("ALTER TABLE bank_transactions ADD CONSTRAINT chk_bt_amount CHECK (amount > 0)");

        // ==========================================
        // DOMAIN 6 - PURCHASING
        // ==========================================
        Schema::create('suppliers', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->string('supplier_name', 255);
            $table->string('contact_person', 255)->nullable();
            $table->string('phone', 30)->nullable();
            $table->string('supplier_address', 255)->nullable();
            $table->foreignUuid('default_currency_id')->nullable()->constrained('currencies')->nullOnDelete();
            $table->uuid('payment_term_id')->nullable();
            $table->uuid('payable_account_id')->nullable();
            $table->decimal('credit_limit', 18, 2)->default(0.00);
            $table->decimal('opening_balance', 18, 2)->default(0.00);
            $table->string('opening_balance_type', 10)->nullable();
            $table->date('opening_balance_date')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
            
            $table->unique(['business_id', 'id']);
            $table->foreign(['business_id', 'payment_term_id'])->references(['business_id', 'id'])->on('payment_terms')->restrictOnDelete();
            $table->foreign(['business_id', 'payable_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE suppliers ADD CONSTRAINT chk_sup_credit CHECK (credit_limit >= 0)");
        DB::statement("ALTER TABLE suppliers ADD CONSTRAINT chk_sup_balance CHECK (opening_balance >= 0)");
        DB::statement("ALTER TABLE suppliers ADD CONSTRAINT chk_sup_bal_type CHECK (opening_balance_type IN ('debit','credit'))");
        DB::statement("ALTER TABLE suppliers ADD CONSTRAINT chk_sup_bal_req CHECK (opening_balance = 0 OR opening_balance_type IS NOT NULL)");

        Schema::create('purchase_invoices', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id');
            $table->uuid('supplier_id');
            $table->uuid('warehouse_id');
            $table->string('invoice_number', 50);
            $table->timestamp('purchase_date')->useCurrent();
            $table->timestamp('due_date')->nullable();
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->decimal('exchange_rate', 18, 8)->default(1.00000000);
            $table->decimal('sub_total', 18, 2)->default(0.00);
            $table->decimal('discount_total', 18, 2)->default(0.00);
            $table->decimal('tax_total', 18, 2)->default(0.00);
            $table->decimal('grand_total', 18, 2)->default(0.00);
            $table->decimal('base_sub_total', 18, 2)->default(0.00);
            $table->decimal('base_discount_total', 18, 2)->default(0.00);
            $table->decimal('base_tax_total', 18, 2)->default(0.00);
            $table->decimal('base_grand_total', 18, 2)->default(0.00);
            $table->string('payment_status', 20)->default('Unpaid');
            $table->string('status', 20)->default('Draft');
            $table->text('notes')->nullable();
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->uuid('posted_by')->nullable();
            $table->timestamp('posted_at')->nullable();
            $table->uuid('reversed_by')->nullable();
            $table->timestamp('reversed_at')->nullable();
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'invoice_number']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
            $table->foreign(['business_id', 'supplier_id'])->references(['business_id', 'id'])->on('suppliers')->restrictOnDelete();
            $table->foreign(['business_id', 'warehouse_id'])->references(['business_id', 'id'])->on('warehouses')->restrictOnDelete();
            $table->foreign(['posted_by'])->references(['id'])->on('users')->restrictOnDelete();
            $table->foreign(['reversed_by'])->references(['id'])->on('users')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE purchase_invoices ADD CONSTRAINT chk_pi_payment CHECK (payment_status IN ('Unpaid','Partial','Paid'))");
        DB::statement("ALTER TABLE purchase_invoices ADD CONSTRAINT chk_pi_status CHECK (status IN ('Draft','Posted','Reversed'))");
        DB::statement("ALTER TABLE purchase_invoices ADD CONSTRAINT chk_pi_dates CHECK (due_date IS NULL OR due_date >= purchase_date)");

        Schema::create('purchase_invoice_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('purchase_invoice_id');
            $table->uuid('product_unit_id');
            $table->uuid('warehouse_id');
            $table->uuid('tax_id')->nullable();
            $table->decimal('quantity', 18, 3);
            $table->decimal('unit_price', 18, 2);
            $table->decimal('discount', 18, 2)->default(0.00);
            $table->decimal('tax', 18, 2)->default(0.00);
            $table->decimal('line_total', 18, 2);
            $table->decimal('base_line_total', 18, 2)->default(0.00);
            
            $table->unique(['business_id', 'id']);
            $table->foreign(['business_id', 'purchase_invoice_id'])->references(['business_id', 'id'])->on('purchase_invoices')->cascadeOnDelete();
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->restrictOnDelete();
            $table->foreign(['business_id', 'warehouse_id'])->references(['business_id', 'id'])->on('warehouses')->restrictOnDelete();
            // $table->foreign(['business_id', 'tax_id'])->references(['business_id', 'id'])->on('taxes')->restrictOnDelete(); // Moved to a later migration to avoid circular dependencies
        });
        DB::statement("ALTER TABLE purchase_invoice_items ADD CONSTRAINT chk_pi_item_quantity CHECK (quantity > 0)");
        DB::statement("ALTER TABLE purchase_invoice_items ADD CONSTRAINT chk_pi_item_price CHECK (unit_price >= 0)");
        DB::statement("ALTER TABLE purchase_invoice_items ADD CONSTRAINT chk_pi_item_discount CHECK (discount >= 0)");
        DB::statement("ALTER TABLE purchase_invoice_items ADD CONSTRAINT chk_pi_item_tax CHECK (tax >= 0)");
        DB::statement("ALTER TABLE purchase_invoice_items ADD CONSTRAINT chk_pi_item_total CHECK (line_total >= 0)");

        Schema::create('purchase_returns', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id');
            $table->uuid('purchase_invoice_id');
            $table->string('return_number', 50);
            $table->timestamp('return_date')->useCurrent();
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->decimal('exchange_rate', 18, 8)->default(1.00000000);
            $table->decimal('total_amount', 18, 2)->default(0.00);
            $table->decimal('base_total_amount', 18, 2)->default(0.00);
            $table->string('status', 20)->default('Draft');
            $table->text('notes')->nullable();
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->softDeletes();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'return_number']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
            $table->foreign(['business_id', 'purchase_invoice_id'])->references(['business_id', 'id'])->on('purchase_invoices')->restrictOnDelete();
        });

        Schema::create('purchase_return_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('purchase_return_id');
            $table->uuid('purchase_invoice_item_id');
            $table->uuid('warehouse_id');
            $table->decimal('quantity', 18, 3);
            $table->decimal('unit_price', 18, 2);
            $table->decimal('line_total', 18, 2);
            $table->decimal('base_line_total', 18, 2)->default(0.00);
            
            $table->unique(['business_id', 'id']);
            $table->foreign(['business_id', 'purchase_return_id'])->references(['business_id', 'id'])->on('purchase_returns')->cascadeOnDelete();
            $table->foreign('purchase_invoice_item_id')->references('id')->on('purchase_invoice_items')->restrictOnDelete();
            $table->foreign(['business_id', 'warehouse_id'])->references(['business_id', 'id'])->on('warehouses')->restrictOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('purchase_return_items');
        Schema::dropIfExists('purchase_returns');
        Schema::dropIfExists('purchase_invoice_items');
        Schema::dropIfExists('purchase_invoices');
        Schema::dropIfExists('suppliers');
        
        Schema::dropIfExists('bank_transactions');
        Schema::dropIfExists('bank_accounts');
        Schema::dropIfExists('cash_transactions');
        Schema::dropIfExists('cash_registers');
        Schema::dropIfExists('payment_methods');
        Schema::dropIfExists('payment_terms');
        Schema::dropIfExists('chart_of_accounts');
        Schema::dropIfExists('exchange_rates');
        Schema::dropIfExists('fiscal_periods');
        Schema::dropIfExists('fiscal_years');
    }
};
