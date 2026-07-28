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
     * Table: cart_items
     * Purpose: Individual line items within a shopping cart.
     */
    public function up(): void
    {
        Schema::create('cart_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('cart_id');
            $table->uuid('product_unit_id');
            $table->decimal('quantity', 18, 3);
            $table->decimal('unit_price', 18, 2);
            $table->decimal('discount', 18, 2)->default(0.00);
            $table->decimal('tax', 18, 2)->default(0.00);
            $table->decimal('line_total', 18, 2);
            $table->timestamps();

            $table->unique(['business_id', 'id']);
        });

        // Composite foreign keys to carts and product_units
        DB::statement('ALTER TABLE cart_items ADD CONSTRAINT fk_ci_cart FOREIGN KEY (business_id, cart_id) REFERENCES carts(business_id, id) ON DELETE CASCADE ON UPDATE CASCADE;');
        DB::statement('ALTER TABLE cart_items ADD CONSTRAINT fk_ci_product_unit FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE RESTRICT ON UPDATE RESTRICT;');

        // Check constraints
        DB::statement('ALTER TABLE cart_items ADD CONSTRAINT chk_cart_item_qty CHECK (quantity > 0);');
        DB::statement('ALTER TABLE cart_items ADD CONSTRAINT chk_cart_item_price CHECK (unit_price >= 0);');
        DB::statement('ALTER TABLE cart_items ADD CONSTRAINT chk_cart_item_discount CHECK (discount >= 0);');
        DB::statement('ALTER TABLE cart_items ADD CONSTRAINT chk_cart_item_tax CHECK (tax >= 0);');
        DB::statement('ALTER TABLE cart_items ADD CONSTRAINT chk_cart_item_total CHECK (line_total >= 0);');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE cart_items DROP CONSTRAINT IF EXISTS fk_ci_product_unit;');
        DB::statement('ALTER TABLE cart_items DROP CONSTRAINT IF EXISTS fk_ci_cart;');
        Schema::dropIfExists('cart_items');
    }
};
