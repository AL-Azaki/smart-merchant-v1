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
     * Tables:
     * 1. Add fields to subscriptions table for installment contracts & offline leases.
     * 2. Create subscription_installments table for installment schedule tracking.
     */
    public function up(): void
    {
        // 1. Extend subscriptions table
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->decimal('total_amount', 18, 2)->default(0.00)->after('amount_paid');
            $table->integer('installments_count')->default(1)->after('total_amount');
            $table->string('installment_frequency', 50)->default('SinglePayment')->after('installments_count');
            $table->timestamp('offline_lease_valid_until')->nullable()->after('status');
            $table->integer('max_offline_days')->default(7)->after('offline_lease_valid_until');
            $table->integer('grace_period_days')->default(3)->after('max_offline_days');
            $table->text('notes')->nullable()->after('grace_period_days');
        });

        // 2. Create subscription_installments table
        Schema::create('subscription_installments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('subscription_id');
            $table->uuid('account_id');
            $table->integer('installment_number')->default(1);
            $table->date('due_date');
            $table->decimal('amount', 18, 2);
            $table->decimal('paid_amount', 18, 2)->default(0.00);
            $table->string('status', 20)->default('Pending');
            $table->timestamp('paid_at')->nullable();
            $table->string('payment_method', 100)->nullable();
            $table->string('transaction_reference', 100)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('subscription_id')
                ->references('id')
                ->on('subscriptions')
                ->onDelete('cascade')
                ->onUpdate('cascade');

            $table->foreign('account_id')
                ->references('id')
                ->on('accounts')
                ->onDelete('cascade')
                ->onUpdate('cascade');
        });

        // Indexes
        DB::statement('CREATE INDEX idx_sub_installments_account_status ON subscription_installments (account_id, status);');
        DB::statement('CREATE INDEX idx_sub_installments_due_date ON subscription_installments (due_date);');

        // Check constraints
        DB::statement('ALTER TABLE subscription_installments ADD CONSTRAINT chk_sub_installments_amount CHECK (amount >= 0);');
        DB::statement('ALTER TABLE subscription_installments ADD CONSTRAINT chk_sub_installments_paid CHECK (paid_amount >= 0 AND paid_amount <= amount);');
        DB::statement("ALTER TABLE subscription_installments ADD CONSTRAINT chk_sub_installments_status CHECK (status IN ('Pending', 'Paid', 'PartiallyPaid', 'Overdue', 'Cancelled'));");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('subscription_installments');

        Schema::table('subscriptions', function (Blueprint $table) {
            $table->dropColumn([
                'total_amount',
                'installments_count',
                'installment_frequency',
                'offline_lease_valid_until',
                'max_offline_days',
                'grace_period_days',
                'notes',
            ]);
        });
    }
};
