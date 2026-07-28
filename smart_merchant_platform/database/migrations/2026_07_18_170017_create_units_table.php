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
     * Table: units
     * Purpose: Units of measurement (e.g., Piece, Kg, Box) scoped per business.
     */
    public function up(): void
    {
        Schema::create('units', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->string('unit_name', 100);
            $table->string('unit_symbol', 10);
            $table->text('unit_description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('business_id')
                ->references('id')
                ->on('businesses')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'unit_name']);
            $table->unique(['business_id', 'unit_symbol']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('units');
    }
};
