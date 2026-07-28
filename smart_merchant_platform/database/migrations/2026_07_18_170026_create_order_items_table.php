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
     * Table: order_items
     * Purpose: Line items for sales orders.
     */
    public function up(): void
    {
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
        });

        // Composite foreign keys to orders and product_units
        DB::statement('ALTER TABLE order_items ADD CONSTRAINT fk_oi_order FOREIGN KEY (business_id, order_id) REFERENCES orders(business_id, id) ON DELETE CASCADE ON UPDATE CASCADE;');
        DB::statement('ALTER TABLE order_items ADD CONSTRAINT fk_oi_product_unit FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT ON UPDATE RESTRICT;');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE order_items DROP CONSTRAINT IF EXISTS fk_oi_product_unit;');
        DB::statement('ALTER TABLE order_items DROP CONSTRAINT IF EXISTS fk_oi_order;');
        Schema::dropIfExists('order_items');
    }
};
