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
     * Table: subscription_payments
     * Purpose: Payment records for subscriptions.
     */
    public function up(): void
    {
        Schema::create('subscription_payments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('subscription_id');
            $table->uuid('account_id');
            $table->uuid('currency_id');
            $table->string('receipt_number', 50)->unique();
            $table->timestamp('payment_date')->default(DB::raw('CURRENT_TIMESTAMP'));
            $table->decimal('amount', 18, 2);
            $table->string('payment_method', 100)->nullable();
            $table->string('reference_number', 100)->nullable();
            $table->string('status', 20)->default('Paid');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('subscription_id')
                ->references('id')
                ->on('subscriptions')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->foreign('account_id')
                ->references('id')
                ->on('accounts')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->foreign('currency_id')
                ->references('id')
                ->on('currencies')
                ->onDelete('restrict')
                ->onUpdate('restrict');
        });

        // Check constraints
        DB::statement('ALTER TABLE subscription_payments ADD CONSTRAINT chk_subscription_payments_amount CHECK (amount > 0);');
        DB::statement("ALTER TABLE subscription_payments ADD CONSTRAINT chk_subscription_payments_status CHECK (status IN ('Draft', 'Paid', 'Voided'));");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('subscription_payments');
    }
};
