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
     * Table: plans
     * Purpose: Subscription plans defining pricing and limits for accounts.
     */
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('plan_name', 100)->unique();
            $table->uuid('currency_id');
            $table->string('billing_cycle', 50);
            $table->integer('duration_months');
            $table->decimal('price', 18, 2);
            $table->integer('max_businesses')->default(1);
            $table->integer('max_branches')->default(1);
            $table->integer('max_users')->default(5);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('currency_id')
                ->references('id')
                ->on('currencies')
                ->onDelete('restrict')
                ->onUpdate('restrict');
        });

        // Check constraints
        DB::statement("ALTER TABLE plans ADD CONSTRAINT chk_plans_billing_cycle CHECK (billing_cycle IN ('Monthly', 'Quarterly', 'SemiAnnual', 'Yearly'));");
        DB::statement('ALTER TABLE plans ADD CONSTRAINT chk_plans_price CHECK (price >= 0);');
        DB::statement('ALTER TABLE plans ADD CONSTRAINT chk_plans_limits CHECK (duration_months > 0 AND max_businesses > 0 AND max_branches > 0 AND max_users > 0);');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('plans');
    }
};
