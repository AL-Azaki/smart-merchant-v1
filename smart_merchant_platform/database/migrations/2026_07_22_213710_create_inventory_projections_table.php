<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('inventory_projections', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('branch_id');
            $table->uuid('product_unit_id');
            $table->decimal('quantity', 18, 4)->default(0.0000);
            $table->integer('revision')->default(1);
            $table->timestamps();

            $table->foreign('business_id')->references('id')->on('businesses')->onDelete('restrict');
            $table->foreign('branch_id')->references('id')->on('branches')->onDelete('restrict');
            $table->foreign('product_unit_id')->references('id')->on('product_units')->onDelete('cascade');

            $table->unique(['business_id', 'branch_id', 'product_unit_id'], 'uq_inv_proj_identity');
        });

        // Composite foreign keys to enforce tenant integrity
        DB::statement('ALTER TABLE inventory_projections ADD CONSTRAINT fk_inv_proj_branch FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT ON UPDATE RESTRICT;');
        DB::statement('ALTER TABLE inventory_projections ADD CONSTRAINT fk_inv_proj_product_unit FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE CASCADE ON UPDATE CASCADE;');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE inventory_projections DROP CONSTRAINT IF EXISTS fk_inv_proj_product_unit;');
        DB::statement('ALTER TABLE inventory_projections DROP CONSTRAINT IF EXISTS fk_inv_proj_branch;');
        Schema::dropIfExists('inventory_projections');
    }
};
