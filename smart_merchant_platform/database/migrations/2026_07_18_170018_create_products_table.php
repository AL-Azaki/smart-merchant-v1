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
     * Table: products
     * Purpose: Master product definitions with category, brand, and tax linkage.
     */
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('category_id')->nullable();
            $table->uuid('brand_id')->nullable();
            $table->uuid('tax_id')->nullable(); // No FK constraint in migration as per spec
            $table->string('product_type', 50)->default('standard');
            $table->string('product_code', 100);
            $table->string('product_name', 255);
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('business_id')
                ->references('id')
                ->on('businesses')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'product_code']);
        });

        // Composite foreign keys to categories and brands
        DB::statement('ALTER TABLE products ADD CONSTRAINT fk_products_category FOREIGN KEY (business_id, category_id) REFERENCES categories(business_id, id) ON DELETE RESTRICT ON UPDATE RESTRICT;');
        DB::statement('ALTER TABLE products ADD CONSTRAINT fk_products_brand FOREIGN KEY (business_id, brand_id) REFERENCES brands(business_id, id) ON DELETE RESTRICT ON UPDATE RESTRICT;');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE products DROP CONSTRAINT IF EXISTS fk_products_brand;');
        DB::statement('ALTER TABLE products DROP CONSTRAINT IF EXISTS fk_products_category;');
        Schema::dropIfExists('products');
    }
};
