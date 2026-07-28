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
     * Table: categories
     * Purpose: Product categories with self-referencing parent for hierarchical structure, scoped per business.
     */
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('parent_id')->nullable();
            $table->string('category_name', 100);
            $table->string('category_code', 50)->nullable();
            $table->text('description')->nullable();
            $table->string('image_path', 500)->nullable();
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('business_id')
                ->references('id')
                ->on('businesses')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'category_name']);
            $table->unique(['business_id', 'category_code']);
        });

        // Composite self-referential FK: (business_id, parent_id) -> categories(business_id, id)
        DB::statement('ALTER TABLE categories ADD CONSTRAINT fk_categories_parent FOREIGN KEY (business_id, parent_id) REFERENCES categories(business_id, id) ON DELETE RESTRICT ON UPDATE RESTRICT;');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE categories DROP CONSTRAINT IF EXISTS fk_categories_parent;');
        Schema::dropIfExists('categories');
    }
};
