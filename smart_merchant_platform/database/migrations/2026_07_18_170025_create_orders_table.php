<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Table: orders
     * Purpose: Sales orders from channels, optionally linked to a customer.
     */
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('branch_id');
            $table->uuid('channel_id');
            $table->uuid('customer_id')->nullable(); // No FK constraint in PostgreSQL migration (Customer owned by SQLite ERP)
            $table->string('order_number', 50);
            $table->timestamp('order_date')->default(DB::raw('CURRENT_TIMESTAMP'));
            $table->uuid('currency_id');
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
            $table->uuid('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('business_id')
                ->references('id')
                ->on('businesses')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->foreign('currency_id')
                ->references('id')
                ->on('currencies')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->foreign('created_by')
                ->references('id')
                ->on('users')
                ->onDelete('set null')
                ->onUpdate('restrict');

            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'order_number']);
        });

        // Composite foreign keys to branches and channels
        DB::statement('ALTER TABLE orders ADD CONSTRAINT fk_orders_branch FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT ON UPDATE RESTRICT;');
        DB::statement('ALTER TABLE orders ADD CONSTRAINT fk_orders_channel FOREIGN KEY (business_id, channel_id) REFERENCES channels(business_id, id) ON DELETE RESTRICT ON UPDATE RESTRICT;');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS fk_orders_channel;');
        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS fk_orders_branch;');
        Schema::dropIfExists('orders');
    }
};
