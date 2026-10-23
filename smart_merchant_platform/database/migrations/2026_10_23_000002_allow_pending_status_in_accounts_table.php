<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Drop existing constraint if present and re-add with 'Pending' included
        DB::statement('ALTER TABLE accounts DROP CONSTRAINT IF EXISTS chk_accounts_status;');
        DB::statement("ALTER TABLE accounts ADD CONSTRAINT chk_accounts_status CHECK (status IN ('Pending', 'Active', 'Suspended', 'Closed'));");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE accounts DROP CONSTRAINT IF EXISTS chk_accounts_status;');
        DB::statement("ALTER TABLE accounts ADD CONSTRAINT chk_accounts_status CHECK (status IN ('Active', 'Suspended', 'Closed'));");
    }
};
