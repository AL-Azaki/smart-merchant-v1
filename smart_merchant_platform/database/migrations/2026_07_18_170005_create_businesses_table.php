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
     * Table: businesses
     * Purpose: A business entity within an account. Central tenant-isolation node — most tables reference business_id.
     */
    public function up(): void
    {
        Schema::create('businesses', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('account_id');
            $table->string('business_name', 255);
            $table->string('business_type', 100)->nullable();
            $table->string('primary_phone', 30)->nullable();
            $table->string('primary_email', 255)->nullable();
            $table->string('logo_path', 500)->nullable();
            $table->string('status', 20)->default('Active');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('account_id')
                ->references('id')
                ->on('accounts')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->unique(['account_id', 'id']);
            $table->unique(['account_id', 'business_name']);
        });

        // Check constraint: chk_businesses_status (Active, Inactive)
        DB::statement("ALTER TABLE businesses ADD CONSTRAINT chk_businesses_status CHECK (status IN ('Active', 'Inactive'));");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('businesses');
    }
};
