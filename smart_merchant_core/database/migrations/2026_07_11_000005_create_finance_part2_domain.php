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
        // DOMAIN 7 - FINANCE (Part 2)
        // ==========================================
        Schema::create('journal_entries', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('fiscal_year_id');
            $table->uuid('fiscal_period_id');
            $table->string('journal_number', 50);
            $table->date('document_date');
            $table->date('posting_date')->nullable();
            $table->string('journal_type', 50);
            $table->string('document_type', 50);
            $table->uuid('document_id')->nullable();
            $table->string('document_number', 50)->nullable();
            $table->uuid('original_journal_id')->nullable();
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->decimal('exchange_rate', 18, 8)->default(1.00000000);
            $table->text('description')->nullable();
            $table->string('status', 20)->default('Draft');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('posted_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->foreignUuid('reversed_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamp('posted_at')->nullable();
            $table->timestamp('reversed_at')->nullable();
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'journal_number']);
            $table->foreign(['business_id', 'fiscal_year_id'])->references(['business_id', 'id'])->on('fiscal_years')->restrictOnDelete();
        });
        Schema::table('journal_entries', function (Blueprint $table) {
            $table->foreign('original_journal_id')->references('id')->on('journal_entries')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE journal_entries ADD CONSTRAINT chk_je_jnl_type CHECK (journal_type IN ('Manual','SalesInvoice','PurchaseInvoice','Payment','InventoryAdjustment','Reverse'))");
        DB::statement("ALTER TABLE journal_entries ADD CONSTRAINT chk_je_doc_type CHECK (document_type IN ('Manual','SalesInvoice','PurchaseInvoice','Payment','InventoryAdjustment','Reverse'))");
        DB::statement("ALTER TABLE journal_entries ADD CONSTRAINT chk_je_status CHECK (status IN ('Draft','Posted','Reversed'))");
        DB::statement('CREATE INDEX idx_je_document ON journal_entries (document_type, document_id)');

        Schema::create('journal_entry_lines', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('journal_entry_id');
            $table->integer('line_number');
            $table->uuid('chart_of_account_id');
            $table->text('description')->nullable();
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->decimal('exchange_rate', 18, 8)->default(1.00000000);
            $table->string('type', 10);
            $table->decimal('foreign_amount', 18, 2)->default(0.00);
            $table->decimal('base_amount', 18, 2)->default(0.00);
            $table->string('document_type', 50)->nullable();
            $table->uuid('document_id')->nullable();
            
            $table->unique(['journal_entry_id', 'line_number']);
            $table->foreign(['business_id', 'journal_entry_id'])->references(['business_id', 'id'])->on('journal_entries')->cascadeOnDelete();
            $table->foreign(['business_id', 'chart_of_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE journal_entry_lines ADD CONSTRAINT chk_jel_type CHECK (type IN ('Debit','Credit'))");
        DB::statement("ALTER TABLE journal_entry_lines ADD CONSTRAINT chk_jel_amount CHECK (foreign_amount >= 0 AND base_amount >= 0)");

        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id');
            $table->string('payment_number', 50);
            $table->timestamp('payment_date')->useCurrent();
            $table->uuid('payment_method_id');
            $table->uuid('chart_of_account_id');
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->decimal('exchange_rate', 18, 8)->default(1.00000000);
            $table->decimal('amount', 18, 2);
            $table->decimal('base_amount', 18, 2);
            $table->string('payment_type', 20);
            $table->string('contact_type', 20)->nullable();
            $table->uuid('contact_id')->nullable();
            $table->string('status', 20)->default('Draft');
            $table->text('notes')->nullable();
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('posted_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamp('posted_at')->nullable();
            $table->foreignUuid('reversed_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamp('reversed_at')->nullable();
            $table->text('reversal_reason')->nullable();
            $table->timestamps();
            $table->softDeletes();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'payment_number']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
            $table->foreign(['business_id', 'payment_method_id'])->references(['business_id', 'id'])->on('payment_methods')->restrictOnDelete();
            $table->foreign(['business_id', 'chart_of_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE payments ADD CONSTRAINT chk_pay_type CHECK (payment_type IN ('Receipt','Payment','Refund','Adjustment','Transfer'))");
        DB::statement("ALTER TABLE payments ADD CONSTRAINT chk_pay_contact_type CHECK (contact_type IN ('Customer','Supplier','Employee','Other'))");
        DB::statement("ALTER TABLE payments ADD CONSTRAINT chk_pay_status CHECK (status IN ('Draft','Posted','Reversed'))");

        Schema::create('payment_allocations', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('payment_id');
            $table->decimal('amount', 18, 2);
            $table->string('document_type', 50);
            $table->uuid('document_id');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->foreign(['business_id', 'payment_id'])->references(['business_id', 'id'])->on('payments')->cascadeOnDelete();
        });
        DB::statement("ALTER TABLE payment_allocations ADD CONSTRAINT chk_pa_amount CHECK (amount > 0)");
        DB::statement('CREATE INDEX idx_payment_allocations_doc ON payment_allocations(document_type, document_id)');

        Schema::create('expense_categories', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->uuid('chart_of_account_id');
            $table->string('category_name', 100);
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'category_name']);
            $table->foreign(['business_id', 'chart_of_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });

        Schema::create('expenses', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id');
            $table->uuid('expense_category_id');
            $table->string('expense_number', 50);
            $table->timestamp('expense_date')->useCurrent();
            $table->uuid('payment_method_id');
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->decimal('exchange_rate', 18, 8)->default(1.00000000);
            $table->decimal('amount', 18, 2);
            $table->decimal('base_amount', 18, 2);
            $table->decimal('tax_amount', 18, 2)->default(0.00);
            $table->string('reference_number', 100)->nullable();
            $table->string('status', 20)->default('Draft');
            $table->text('notes')->nullable();
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->softDeletes();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'expense_number']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
            $table->foreign(['business_id', 'expense_category_id'])->references(['business_id', 'id'])->on('expense_categories')->restrictOnDelete();
            $table->foreign(['business_id', 'payment_method_id'])->references(['business_id', 'id'])->on('payment_methods')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE expenses ADD CONSTRAINT chk_exp_status CHECK (status IN ('Draft','Posted','Cancelled'))");

        Schema::create('opening_balances', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('fiscal_year_id');
            $table->uuid('chart_of_account_id');
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->decimal('exchange_rate', 18, 8)->default(1.00000000);
            $table->decimal('debit_amount', 18, 2)->default(0.00);
            $table->decimal('credit_amount', 18, 2)->default(0.00);
            $table->decimal('base_debit_amount', 18, 2)->default(0.00);
            $table->decimal('base_credit_amount', 18, 2)->default(0.00);
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            
            $table->unique(['fiscal_year_id', 'chart_of_account_id']);
            $table->foreign(['business_id', 'fiscal_year_id'])->references(['business_id', 'id'])->on('fiscal_years')->restrictOnDelete();
            $table->foreign(['business_id', 'chart_of_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE opening_balances ADD CONSTRAINT chk_ob_xor CHECK ((debit_amount >= 0 AND credit_amount = 0) OR (debit_amount = 0 AND credit_amount >= 0))");
        DB::statement("ALTER TABLE opening_balances ADD CONSTRAINT chk_ob_base_xor CHECK ((base_debit_amount >= 0 AND base_credit_amount = 0) OR (base_debit_amount = 0 AND base_credit_amount >= 0))");
    }

    public function down(): void
    {
        Schema::dropIfExists('opening_balances');
        Schema::dropIfExists('expenses');
        Schema::dropIfExists('expense_categories');
        Schema::dropIfExists('payment_allocations');
        Schema::dropIfExists('payments');
        Schema::dropIfExists('journal_entry_lines');
        Schema::dropIfExists('journal_entries');
    }
};
