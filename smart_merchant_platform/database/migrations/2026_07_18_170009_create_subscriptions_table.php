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
     * Table: subscriptions
     * Purpose: Active subscription linking an account to a plan.
     */
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('account_id');
            $table->uuid('plan_id');
            $table->date('start_date');
            $table->date('end_date');
            $table->decimal('amount_paid', 18, 2)->default(0.00);
            $table->string('status', 20)->default('Active');
            $table->timestamps();

            $table->foreign('account_id')
                ->references('id')
                ->on('accounts')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->foreign('plan_id')
                ->references('id')
                ->on('plans')
                ->onDelete('restrict')
                ->onUpdate('restrict');
        });

        // Partial unique index: uq_subscriptions_active_account WHERE status = 'Active' per account
        DB::statement("CREATE UNIQUE INDEX uq_subscriptions_active_account ON subscriptions (account_id, status) WHERE status = 'Active';");

        // Check constraints
        DB::statement('ALTER TABLE subscriptions ADD CONSTRAINT chk_subscriptions_dates CHECK (end_date >= start_date);');
        DB::statement('ALTER TABLE subscriptions ADD CONSTRAINT chk_subscriptions_amount CHECK (amount_paid >= 0);');
        DB::statement("ALTER TABLE subscriptions ADD CONSTRAINT chk_subscriptions_status CHECK (status IN ('Active', 'Expired', 'Cancelled'));");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
