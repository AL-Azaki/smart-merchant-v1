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
     * Table: currencies
     * Purpose: Global currency definitions with exchange rates. Shared across all businesses.
     */
    public function up(): void
    {
        Schema::create('currencies', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('currency_code', 10)->unique();
            $table->string('currency_name_ar', 100);
            $table->string('currency_name_en', 100);
            $table->string('currency_symbol', 10);
            $table->integer('decimal_places')->default(2);
            $table->decimal('exchange_rate', 18, 8)->default(1.00000000);
            $table->boolean('is_base_currency')->default(false);
            $table->boolean('is_active')->default(true);
        });

        // Partial unique index: uq_currencies_single_base WHERE is_base_currency = TRUE
        DB::statement('CREATE UNIQUE INDEX uq_currencies_single_base ON currencies (is_base_currency) WHERE is_base_currency = TRUE;');

        // Check constraints: chk_currencies_decimals (0–6), chk_currencies_exchange_rate (> 0)
        DB::statement('ALTER TABLE currencies ADD CONSTRAINT chk_currencies_decimals CHECK (decimal_places >= 0 AND decimal_places <= 6);');
        DB::statement('ALTER TABLE currencies ADD CONSTRAINT chk_currencies_exchange_rate CHECK (exchange_rate > 0);');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('currencies');
    }
};
