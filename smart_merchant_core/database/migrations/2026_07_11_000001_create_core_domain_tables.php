<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Currencies (Dependency for Plans and Finance)
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

        DB::statement('ALTER TABLE currencies ADD CONSTRAINT chk_currencies_decimals CHECK (decimal_places BETWEEN 0 AND 6)');
        DB::statement('ALTER TABLE currencies ADD CONSTRAINT chk_currencies_exchange_rate CHECK (exchange_rate > 0)');
        DB::statement('CREATE UNIQUE INDEX uq_currencies_single_base ON currencies (is_base_currency) WHERE is_base_currency = TRUE');

        // 2. Accounts
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
        DB::statement("ALTER TABLE accounts ADD CONSTRAINT chk_accounts_status CHECK (status IN ('Active','Suspended','Closed'))");

        // 3. Businesses
        Schema::create('businesses', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('account_id')->constrained('accounts')->restrictOnDelete();
            $table->string('business_name', 255);
            $table->string('business_type', 100)->nullable();
            $table->string('primary_phone', 30)->nullable();
            $table->string('primary_email', 255)->nullable();
            $table->string('logo_path', 500)->nullable();
            $table->string('status', 20)->default('Active');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['account_id', 'id']);
            $table->unique(['account_id', 'business_name']);
        });
        DB::statement("ALTER TABLE businesses ADD CONSTRAINT chk_businesses_status CHECK (status IN ('Active','Inactive'))");

        // 4. Branches
        Schema::create('branches', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->string('branch_name', 255);
            $table->string('branch_code', 50);
            $table->string('phone', 30)->nullable();
            $table->string('email', 255)->nullable();
            $table->text('address')->nullable();
            $table->boolean('is_default')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'branch_code']);
        });
        DB::statement('CREATE UNIQUE INDEX uq_branches_single_default ON branches (business_id) WHERE is_default = TRUE');

        // 5. Plans
        Schema::create('plans', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('plan_name', 100)->unique();
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->string('billing_cycle', 50);
            $table->integer('duration_months');
            $table->decimal('price', 18, 2);
            $table->integer('max_businesses')->default(1);
            $table->integer('max_branches')->default(1);
            $table->integer('max_users')->default(5);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
        DB::statement("ALTER TABLE plans ADD CONSTRAINT chk_plans_billing_cycle CHECK (billing_cycle IN ('Monthly', 'Quarterly', 'SemiAnnual', 'Yearly'))");
        DB::statement("ALTER TABLE plans ADD CONSTRAINT chk_plans_price CHECK (price >= 0)");
        DB::statement("ALTER TABLE plans ADD CONSTRAINT chk_plans_limits CHECK (duration_months > 0 AND max_businesses > 0 AND max_branches > 0 AND max_users > 0)");

        // 6. Subscriptions
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('account_id')->constrained('accounts')->restrictOnDelete();
            $table->foreignUuid('plan_id')->constrained('plans')->restrictOnDelete();
            $table->date('start_date');
            $table->date('end_date');
            $table->decimal('amount_paid', 18, 2)->default(0.00);
            $table->string('status', 20)->default('Active');
            $table->timestamps();
        });
        DB::statement("ALTER TABLE subscriptions ADD CONSTRAINT chk_subscriptions_dates CHECK (end_date >= start_date)");
        DB::statement("ALTER TABLE subscriptions ADD CONSTRAINT chk_subscriptions_amount CHECK (amount_paid >= 0)");
        DB::statement("ALTER TABLE subscriptions ADD CONSTRAINT chk_subscriptions_status CHECK (status IN ('Active','Expired','Cancelled'))");
        DB::statement("CREATE UNIQUE INDEX uq_subscriptions_active_account ON subscriptions (account_id) WHERE status = 'Active'");

        // 7. Subscription Payments
        Schema::create('subscription_payments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('subscription_id')->constrained('subscriptions')->restrictOnDelete();
            $table->foreignUuid('account_id')->constrained('accounts')->restrictOnDelete();
            $table->foreignUuid('currency_id')->constrained('currencies')->restrictOnDelete();
            $table->string('receipt_number', 50)->unique();
            $table->timestamp('payment_date')->useCurrent();
            $table->decimal('amount', 18, 2);
            $table->string('payment_method', 100)->nullable();
            $table->string('reference_number', 100)->nullable();
            $table->string('status', 20)->default('Paid');
            $table->text('notes')->nullable();
            $table->timestamps();
        });
        DB::statement("ALTER TABLE subscription_payments ADD CONSTRAINT chk_subscription_payments_amount CHECK (amount > 0)");
        DB::statement("ALTER TABLE subscription_payments ADD CONSTRAINT chk_subscription_payments_status CHECK (status IN ('Draft','Paid','Voided'))");

        // 8. Roles & Permissions
        Schema::create('roles', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->string('role_name', 100);
            $table->text('description')->nullable();
            $table->boolean('is_system_role')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'role_name']);
        });

        Schema::create('permissions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('module', 100);
            $table->string('permission_code', 100)->unique();
            $table->string('permission_name', 100);
            $table->text('description')->nullable();
        });

        // 9. Users
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('account_id')->constrained('accounts')->restrictOnDelete();
            $table->uuid('default_branch_id')->nullable();
            $table->string('username', 50);
            $table->string('email', 255)->unique();
            $table->string('password_hash', 255);
            $table->string('full_name', 255);
            $table->string('phone', 30)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['account_id', 'username']);
        });

        Schema::create('user_roles', function (Blueprint $table) {
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('role_id')->constrained('roles')->cascadeOnDelete();
            $table->timestamp('assigned_at')->useCurrent();
            $table->primary(['user_id', 'role_id']);
        });

        Schema::create('role_permissions', function (Blueprint $table) {
            $table->foreignUuid('role_id')->constrained('roles')->cascadeOnDelete();
            $table->foreignUuid('permission_id')->constrained('permissions')->cascadeOnDelete();
            $table->primary(['role_id', 'permission_id']);
        });

        Schema::create('user_branches', function (Blueprint $table) {
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('branch_id')->constrained('branches')->cascadeOnDelete();
            $table->boolean('is_active')->default(true);
            $table->timestamp('assigned_at')->useCurrent();
            $table->primary(['user_id', 'branch_id']);
            $table->unique(['user_id', 'branch_id'], 'uq_user_branches');
        });

        // Add circular FK for users
        Schema::table('users', function (Blueprint $table) {
            // Need raw SQL for composite foreign key in basic Laravel migration
            DB::statement('ALTER TABLE users ADD CONSTRAINT fk_users_default_branch FOREIGN KEY (id, default_branch_id) REFERENCES user_branches(user_id, branch_id) ON DELETE RESTRICT');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            DB::statement('ALTER TABLE users DROP CONSTRAINT fk_users_default_branch');
        });
        Schema::dropIfExists('user_branches');
        Schema::dropIfExists('role_permissions');
        Schema::dropIfExists('user_roles');
        Schema::dropIfExists('users');
        Schema::dropIfExists('permissions');
        Schema::dropIfExists('roles');
        Schema::dropIfExists('subscription_payments');
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('plans');
        Schema::dropIfExists('branches');
        Schema::dropIfExists('businesses');
        Schema::dropIfExists('accounts');
        Schema::dropIfExists('currencies');
    }
};
