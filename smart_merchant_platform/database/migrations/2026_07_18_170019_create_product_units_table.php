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
     * Table: product_units
     * Purpose: Product-unit combinations with pricing. Each product can have multiple units (e.g., Piece, Box of 12).
     */
    public function up(): void
    {
        Schema::create('product_units', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('product_id');
            $table->uuid('unit_id');
            $table->string('sku', 100)->nullable();
            $table->string('barcode', 100)->nullable();
            $table->decimal('conversion_factor', 18, 4)->default(1.0000);
            $table->decimal('purchase_price', 18, 2)->default(0.00);
            $table->decimal('selling_price', 18, 2)->default(0.00);
            $table->decimal('minimum_price', 18, 2)->default(0.00);
            $table->boolean('is_base_unit')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('business_id')
                ->references('id')
                ->on('businesses')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->foreign('unit_id')
                ->references('id')
                ->on('units')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'barcode']);
            $table->unique(['business_id', 'sku']);
            $table->unique(['product_id', 'unit_id']);
        });

        // Composite FK: (business_id, product_id) -> products(business_id, id)
        DB::statement('ALTER TABLE product_units ADD CONSTRAINT fk_product_units_product FOREIGN KEY (business_id, product_id) REFERENCES products(business_id, id) ON DELETE CASCADE ON UPDATE CASCADE;');

        // Partial unique index: uq_product_units_one_base WHERE is_base_unit = TRUE per product
        DB::statement('CREATE UNIQUE INDEX uq_product_units_one_base ON product_units (product_id, is_base_unit) WHERE is_base_unit = TRUE;');

        // Check constraints
        DB::statement('ALTER TABLE product_units ADD CONSTRAINT chk_pu_conversion CHECK (conversion_factor > 0);');
        DB::statement('ALTER TABLE product_units ADD CONSTRAINT chk_pu_prices CHECK (purchase_price >= 0 AND selling_price >= minimum_price AND minimum_price >= 0);');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE product_units DROP CONSTRAINT IF EXISTS fk_product_units_product;');
        Schema::dropIfExists('product_units');
    }
};
