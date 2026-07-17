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
        // DOMAIN 8 - SALES CHANNEL
        // ==========================================
        Schema::create('product_channels', function (Blueprint $table) {
            $table->uuid('business_id');
            $table->uuid('product_unit_id');
            $table->uuid('channel_id');
            $table->decimal('sale_price', 18, 2);
            $table->boolean('is_enabled')->default(true);
            $table->integer('display_order')->default(0);
            
            $table->primary(['business_id', 'product_unit_id', 'channel_id']);
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->cascadeOnDelete();
            $table->foreign(['business_id', 'channel_id'])->references(['business_id', 'id'])->on('channels')->cascadeOnDelete();
        });

        Schema::create('carts', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('channel_id');
            $table->uuid('customer_id')->nullable();
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->string('status', 20)->default('Active');
            $table->decimal('sub_total', 18, 2)->default(0.00);
            $table->decimal('tax_total', 18, 2)->default(0.00);
            $table->decimal('grand_total', 18, 2)->default(0.00);
            $table->timestamps();
            
            $table->foreign(['business_id', 'channel_id'])->references(['business_id', 'id'])->on('channels')->restrictOnDelete();
            $table->foreign(['business_id', 'customer_id'])->references(['business_id', 'id'])->on('customers')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE carts ADD CONSTRAINT chk_carts_status CHECK (status IN ('Active','Converted','Abandoned'))");
        DB::statement("CREATE UNIQUE INDEX uq_carts_active_customer ON carts (business_id, customer_id) WHERE status = 'Active'");

        Schema::create('cart_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->foreignUuid('cart_id')->constrained('carts')->cascadeOnDelete();
            $table->uuid('product_unit_id');
            $table->decimal('quantity', 18, 3);
            $table->decimal('unit_price', 18, 2);
            $table->decimal('tax', 18, 2)->default(0.00);
            $table->decimal('line_total', 18, 2);
            $table->decimal('base_line_total', 18, 2)->default(0.00);
            
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->restrictOnDelete();
        });

        // ==========================================
        // DOMAIN 9 - SYSTEM
        // ==========================================
        Schema::create('system_settings', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->nullable()->constrained('businesses')->cascadeOnDelete();
            $table->string('scope_business_id', 50);
            $table->string('setting_group', 50);
            $table->string('setting_key', 100);
            $table->jsonb('setting_value')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();
            
            $table->unique(['scope_business_id', 'setting_key']);
        });

        Schema::create('print_settings', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->foreignUuid('branch_id')->nullable()->constrained('branches')->cascadeOnDelete();
            $table->string('printer_name', 100)->nullable();
            $table->string('paper_size', 50)->nullable();
            $table->text('receipt_header')->nullable();
            $table->text('receipt_footer')->nullable();
            $table->string('print_format', 50)->nullable();
            $table->timestamps();
            
            $table->unique(['business_id', 'branch_id']);
        });

        Schema::create('sequences', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->nullable()->constrained('businesses')->cascadeOnDelete();
            $table->foreignUuid('branch_id')->nullable()->constrained('branches')->cascadeOnDelete();
            $table->string('branch_scope_id', 50);
            $table->string('document_type', 50);
            $table->string('prefix', 20)->nullable();
            $table->bigInteger('next_number')->default(1);
            $table->integer('padding')->default(5);
            
            $table->unique(['business_id', 'branch_scope_id', 'document_type']);
        });
        DB::statement("ALTER TABLE sequences ADD CONSTRAINT chk_seq_type CHECK (document_type IN ('SalesInvoice','PurchaseInvoice','SalesReturn','PurchaseReturn','SalesOrder','PurchaseOrder','Payment','JournalEntry','Transfer'))");

        // ==========================================
        // DOMAIN 10 - HR
        // ==========================================
        Schema::create('departments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->string('department_name', 100);
            $table->uuid('manager_id')->nullable();
            $table->boolean('is_active')->default(true);
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'department_name']);
        });

        Schema::create('job_titles', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->string('title_name', 100);
            $table->boolean('is_active')->default(true);
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'title_name']);
        });

        Schema::create('employees', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id');
            $table->uuid('department_id');
            $table->uuid('job_title_id');
            $table->foreignUuid('user_id')->nullable()->unique()->constrained('users')->nullOnDelete();
            $table->string('employee_code', 50);
            $table->string('first_name', 100);
            $table->string('last_name', 100);
            $table->string('email', 255)->nullable();
            $table->string('phone', 30)->nullable();
            $table->date('hire_date');
            $table->decimal('base_salary', 18, 2)->default(0.00);
            $table->string('status', 20)->default('Active');
            $table->timestamps();
            $table->softDeletes();
            
            $table->unique(['business_id', 'employee_code']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
            $table->foreign(['business_id', 'department_id'])->references(['business_id', 'id'])->on('departments')->restrictOnDelete();
            $table->foreign(['business_id', 'job_title_id'])->references(['business_id', 'id'])->on('job_titles')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE employees ADD CONSTRAINT chk_emp_status CHECK (status IN ('Active','OnLeave','Terminated'))");

        Schema::create('employee_documents', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->string('document_type', 50);
            $table->string('document_path', 500);
            $table->timestamp('upload_date')->useCurrent();
        });

        // ==========================================
        // DOMAIN 11 - EXTENDED FEATURES
        // ==========================================
        Schema::create('taxes', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->string('tax_name', 100);
            $table->decimal('tax_rate', 5, 2);
            $table->boolean('is_active')->default(true);
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'tax_name']);
        });
        DB::statement("ALTER TABLE taxes ADD CONSTRAINT chk_tax_rate_positive CHECK (tax_rate >= 0)");

        Schema::create('product_taxes', function (Blueprint $table) {
            $table->uuid('business_id');
            $table->uuid('product_unit_id');
            $table->uuid('tax_id');
            
            $table->primary(['business_id', 'product_unit_id', 'tax_id']);
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->cascadeOnDelete();
            $table->foreign(['business_id', 'tax_id'])->references(['business_id', 'id'])->on('taxes')->cascadeOnDelete();
        });

        Schema::create('product_variants', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->uuid('product_unit_id');
            $table->string('variant_name', 100);
            $table->string('variant_value', 100);
            
            $table->unique(['product_unit_id', 'variant_name']);
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->cascadeOnDelete();
        });

        Schema::create('stock_adjustments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('warehouse_id');
            $table->string('adjustment_number', 50);
            $table->timestamp('adjustment_date')->useCurrent();
            $table->string('adjustment_type', 20);
            $table->string('status', 20)->default('Draft');
            $table->text('notes')->nullable();
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->softDeletes();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'adjustment_number']);
            $table->foreign(['business_id', 'warehouse_id'])->references(['business_id', 'id'])->on('warehouses')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE stock_adjustments ADD CONSTRAINT chk_sa_type CHECK (adjustment_type IN ('Increase','Decrease','Damage','Loss'))");
        DB::statement("ALTER TABLE stock_adjustments ADD CONSTRAINT chk_sa_status CHECK (status IN ('Draft','Posted'))");

        Schema::create('stock_adjustment_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('adjustment_id');
            $table->uuid('product_unit_id');
            $table->decimal('system_qty', 18, 3);
            $table->decimal('physical_qty', 18, 3);
            $table->decimal('diff_qty', 18, 3);
            
            $table->foreign(['business_id', 'adjustment_id'])->references(['business_id', 'id'])->on('stock_adjustments')->cascadeOnDelete();
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE stock_adjustment_items ADD CONSTRAINT chk_sai_diff CHECK (diff_qty = physical_qty - system_qty)");

        Schema::create('attachments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->string('entity_type', 50);
            $table->uuid('entity_id');
            $table->string('file_path', 500);
            $table->string('file_name', 255);
            $table->timestamp('upload_date')->useCurrent();
        });
        DB::statement("CREATE INDEX idx_attachments_entity ON attachments (business_id, entity_type, entity_id)");

        Schema::create('activity_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->foreignUuid('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action', 100);
            $table->string('entity_type', 50);
            $table->uuid('entity_id')->nullable();
            $table->jsonb('details')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
        DB::statement("CREATE INDEX idx_activity_logs_lookup ON activity_logs (business_id, entity_type, entity_id)");

        Schema::create('fixed_assets', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id')->nullable();
            $table->uuid('asset_category_id')->nullable();
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->string('asset_code', 50);
            $table->string('asset_name', 255);
            $table->date('acquisition_date');
            $table->decimal('acquisition_cost', 18, 2);
            $table->decimal('base_acquisition_cost', 18, 2);
            $table->integer('useful_life');
            $table->decimal('residual_value', 18, 2)->default(0.00);
            $table->decimal('base_residual_value', 18, 2)->default(0.00);
            $table->string('depreciation_method', 50);
            $table->date('depreciation_start_date');
            $table->string('status', 30)->default('Draft');
            $table->foreignUuid('responsible_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'asset_code']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE fixed_assets ADD CONSTRAINT chk_fa_status CHECK (status IN ('Draft','Active','Depreciating','Fully Depreciated','Disposed'))");
        DB::statement("ALTER TABLE fixed_assets ADD CONSTRAINT chk_fa_cost CHECK (acquisition_cost >= 0 AND base_acquisition_cost >= 0)");
        DB::statement("ALTER TABLE fixed_assets ADD CONSTRAINT chk_fa_life CHECK (useful_life > 0)");
        DB::statement("ALTER TABLE fixed_assets ADD CONSTRAINT chk_fa_residual CHECK (residual_value >= 0 AND base_residual_value >= 0)");

        Schema::create('depreciation_schedules', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('fixed_asset_id');
            $table->integer('depreciation_period');
            $table->date('scheduled_posting_date');
            $table->decimal('depreciation_amount', 18, 2);
            $table->decimal('base_depreciation_amount', 18, 2);
            $table->decimal('accumulated_depreciation', 18, 2);
            $table->decimal('base_accumulated_depreciation', 18, 2);
            $table->decimal('remaining_book_value', 18, 2);
            $table->decimal('base_remaining_book_value', 18, 2);
            $table->string('status', 30)->default('Pending');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            
            $table->unique(['business_id', 'fixed_asset_id', 'depreciation_period'], 'uq_dep_schedule_period');
            $table->foreign(['business_id', 'fixed_asset_id'])->references(['business_id', 'id'])->on('fixed_assets')->cascadeOnDelete();
        });
        DB::statement("ALTER TABLE depreciation_schedules ADD CONSTRAINT chk_ds_status CHECK (status IN ('Pending','Ready','Posted','Cancelled'))");
        DB::statement("ALTER TABLE depreciation_schedules ADD CONSTRAINT chk_ds_amount CHECK (depreciation_amount >= 0 AND base_depreciation_amount >= 0)");

        Schema::create('bank_reconciliations', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('chart_of_account_id');
            $table->date('statement_date');
            $table->decimal('statement_balance', 18, 2);
            $table->decimal('system_balance', 18, 2);
            $table->decimal('difference', 18, 2);
            $table->string('status', 20)->default('Draft');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'chart_of_account_id', 'statement_date'], 'uq_bank_recon_date');
            $table->foreign(['business_id', 'chart_of_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE bank_reconciliations ADD CONSTRAINT chk_br_status CHECK (status IN ('Draft','Completed'))");

        Schema::create('bank_reconciliation_lines', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('bank_reconciliation_id');
            $table->uuid('payment_id');
            $table->boolean('is_cleared')->default(false);
            
            $table->foreign(['business_id', 'bank_reconciliation_id'])->references(['business_id', 'id'])->on('bank_reconciliations')->cascadeOnDelete();
            $table->foreign(['business_id', 'payment_id'])->references(['business_id', 'id'])->on('payments')->restrictOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bank_reconciliation_lines');
        Schema::dropIfExists('bank_reconciliations');
        Schema::dropIfExists('depreciation_schedules');
        Schema::dropIfExists('fixed_assets');
        Schema::dropIfExists('activity_logs');
        Schema::dropIfExists('attachments');
        Schema::dropIfExists('stock_adjustment_items');
        Schema::dropIfExists('stock_adjustments');
        Schema::dropIfExists('product_variants');
        Schema::dropIfExists('product_taxes');
        Schema::dropIfExists('taxes');
        
        Schema::dropIfExists('employee_documents');
        Schema::dropIfExists('employees');
        Schema::dropIfExists('job_titles');
        Schema::dropIfExists('departments');
        
        Schema::dropIfExists('sequences');
        Schema::dropIfExists('print_settings');
        Schema::dropIfExists('system_settings');
        
        Schema::dropIfExists('cart_items');
        Schema::dropIfExists('carts');
        Schema::dropIfExists('product_channels');
    }
};
