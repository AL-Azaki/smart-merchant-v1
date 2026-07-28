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
     * Table: accounts
     * Purpose: Top-level tenant account (organization). Each account can own multiple businesses.
     */
    public function up(): void
    {
        Schema::create('accounts', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('name', 200);
            $table->string('owner_name', 150);
            $table->string('email', 255)->unique();
            $table->string('phone', 30)->nullable();
            $table->string('status', 20)->default('Active');
            $table->timestamps();
            $table->softDeletes();
        });

        // Check constraint: chk_accounts_status (Active, Suspended, Closed)
        DB::statement("ALTER TABLE accounts ADD CONSTRAINT chk_accounts_status CHECK (status IN ('Active', 'Suspended', 'Closed'));");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('accounts');
    }
};
