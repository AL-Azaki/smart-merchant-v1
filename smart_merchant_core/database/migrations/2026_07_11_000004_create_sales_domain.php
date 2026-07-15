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
        // DOMAIN 5 - SALES
        // ==========================================
        Schema::create('customers', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->string('customer_name', 255);
            $table->string('phone', 30)->nullable();
            $table->string('email', 255)->nullable();
            $table->text('address')->nullable();
            $table->decimal('credit_limit', 18, 2)->default(0.00);
            $table->foreignUuid('default_currency_id')->nullable()->constrained('currencies')->nullOnDelete();
            $table->uuid('payment_term_id')->nullable();
            $table->uuid('receivable_account_id')->nullable();
            $table->decimal('opening_balance', 18, 2)->default(0.00);
            $table->string('opening_balance_type', 10)->nullable();
            $table->date('opening_balance_date')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
            
            $table->unique(['business_id', 'id']);
            $table->foreign(['business_id', 'payment_term_id'])->references(['business_id', 'id'])->on('payment_terms')->restrictOnDelete();
            $table->foreign(['business_id', 'receivable_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE customers ADD CONSTRAINT chk_cust_credit CHECK (credit_limit >= 0)");
        DB::statement("ALTER TABLE customers ADD CONSTRAINT chk_cust_balance CHECK (opening_balance >= 0)");
        DB::statement("ALTER TABLE customers ADD CONSTRAINT chk_cust_bal_type CHECK (opening_balance_type IN ('debit','credit'))");
        DB::statement("ALTER TABLE customers ADD CONSTRAINT chk_cust_bal_req CHECK (opening_balance = 0 OR opening_balance_type IS NOT NULL)");

        Schema::create('channels', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->string('channel_name', 100);
            $table->string('channel_code', 50);
            $table->string('channel_type', 50);
            $table->boolean('is_active')->default(true);
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'channel_code']);
        });
        DB::statement("ALTER TABLE channels ADD CONSTRAINT chk_chan_type CHECK (channel_type IN ('POS','Ecommerce','B2B','Marketplace','Other'))");

        Schema::create('sales_invoices', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id');
            $table->uuid('customer_id')->nullable(); // Null for walk-in
            $table->string('invoice_number', 50);
            $table->timestamp('invoice_date')->useCurrent();
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
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'invoice_number']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
            $table->foreign(['business_id', 'customer_id'])->references(['business_id', 'id'])->on('customers')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE sales_invoices ADD CONSTRAINT chk_si_payment CHECK (payment_status IN ('Unpaid','Partial','Paid'))");
        DB::statement("ALTER TABLE sales_invoices ADD CONSTRAINT chk_si_status CHECK (status IN ('Draft','Posted','Reversed'))");
        DB::statement('CREATE INDEX idx_sales_invoices_status ON sales_invoices(status, payment_status)');

        Schema::create('orders', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id');
            $table->uuid('channel_id');
            $table->uuid('customer_id')->nullable();
            $table->string('order_number', 50);
            $table->timestamp('order_date')->useCurrent();
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
            $table->string('status', 30)->default('Pending');
            $table->text('notes')->nullable();
            $table->foreignUuid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'order_number']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
            $table->foreign(['business_id', 'channel_id'])->references(['business_id', 'id'])->on('channels')->restrictOnDelete();
            $table->foreign(['business_id', 'customer_id'])->references(['business_id', 'id'])->on('customers')->restrictOnDelete();
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('order_id');
            $table->uuid('product_unit_id');
            $table->decimal('quantity', 18, 3);
            $table->decimal('unit_price', 18, 2);
            $table->decimal('discount', 18, 2)->default(0.00);
            $table->decimal('tax', 18, 2)->default(0.00);
            $table->decimal('line_total', 18, 2);
            $table->decimal('base_line_total', 18, 2)->default(0.00);
            
            $table->unique(['business_id', 'id']);
            $table->foreign(['business_id', 'order_id'])->references(['business_id', 'id'])->on('orders')->cascadeOnDelete();
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->restrictOnDelete();
        });

        Schema::create('sales_invoice_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('sales_invoice_id');
            $table->foreignUuid('order_item_id')->nullable()->constrained('order_items')->nullOnDelete();
            $table->uuid('product_unit_id');
            $table->uuid('warehouse_id');
            $table->uuid('tax_id')->nullable();
            $table->decimal('quantity', 18, 3);
            $table->decimal('unit_price', 18, 2);
            $table->decimal('cost_price', 18, 2)->default(0.00);
            $table->decimal('discount', 18, 2)->default(0.00);
            $table->decimal('tax', 18, 2)->default(0.00);
            $table->decimal('line_total', 18, 2);
            $table->decimal('cost_total', 18, 2)->default(0.00);
            $table->decimal('base_line_total', 18, 2)->default(0.00);
            
            $table->unique(['business_id', 'id']);
            $table->foreign(['business_id', 'sales_invoice_id'])->references(['business_id', 'id'])->on('sales_invoices')->cascadeOnDelete();
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->restrictOnDelete();
            $table->foreign(['business_id', 'warehouse_id'])->references(['business_id', 'id'])->on('warehouses')->restrictOnDelete();
            $table->foreign(['business_id', 'tax_id'])->references(['business_id', 'id'])->on('taxes')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE sales_invoice_items ADD CONSTRAINT chk_sii_quantity CHECK (quantity > 0)");
        DB::statement("ALTER TABLE sales_invoice_items ADD CONSTRAINT chk_sii_price CHECK (unit_price >= 0)");
        DB::statement("ALTER TABLE sales_invoice_items ADD CONSTRAINT chk_sii_discount CHECK (discount >= 0)");

        Schema::create('sales_returns', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id');
            $table->uuid('sales_invoice_id');
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
            $table->foreign(['business_id', 'sales_invoice_id'])->references(['business_id', 'id'])->on('sales_invoices')->restrictOnDelete();
        });

        Schema::create('sales_return_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('sales_return_id');
            $table->foreignUuid('sales_invoice_item_id')->constrained('sales_invoice_items')->restrictOnDelete();
            $table->uuid('warehouse_id');
            $table->decimal('quantity', 18, 3);
            $table->decimal('unit_price', 18, 2);
            $table->decimal('cost_price', 18, 2)->default(0.00);
            $table->decimal('total_price', 18, 2);
            $table->decimal('cost_total', 18, 2)->default(0.00);
            $table->decimal('base_total_price', 18, 2)->default(0.00);
            
            $table->unique(['business_id', 'id']);
            $table->foreign(['business_id', 'sales_return_id'])->references(['business_id', 'id'])->on('sales_returns')->cascadeOnDelete();
            $table->foreign(['business_id', 'warehouse_id'])->references(['business_id', 'id'])->on('warehouses')->restrictOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sales_return_items');
        Schema::dropIfExists('sales_returns');
        Schema::dropIfExists('sales_invoice_items');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('sales_invoices');
        Schema::dropIfExists('channels');
        Schema::dropIfExists('customers');
    }
};
