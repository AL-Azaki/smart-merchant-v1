<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use App\Domains\Core\Models\Plan;
use App\Domains\Core\Models\Currency;
use App\Domains\Core\Models\Account;
use App\Domains\Core\DTOs\CreateBusinessDTO;
use App\Domains\Core\Actions\Business\CreateBusinessAction;

class DatabaseSeeder extends Seeder
{
    public function run(CreateBusinessAction $createBusinessAction): void
    {
        // 1. Run prerequisite Seeders
        $this->call([
            AccountTypeSeeder::class,
        ]);

        DB::transaction(function () use ($createBusinessAction) {
            // 2. Create Base Currency
            $currency = Currency::create([
                'currency_code' => 'USD',
                'currency_name_ar' => 'دولار أمريكي',
                'currency_name_en' => 'US Dollar',
                'currency_symbol' => '$',
                'decimal_places' => 2,
                'exchange_rate' => 1.000000,
                'is_base_currency' => true,
                'is_active' => true,
            ]);

            // 3. Create Base Plan
            $plan = Plan::create([
                'plan_name' => 'Enterprise Plan',
                'price' => 0.00,
                'currency_id' => $currency->id,
                'billing_cycle' => 'Yearly',
                'duration_months' => 12,
                'max_businesses' => 10,
                'max_users' => 100,
                'max_branches' => 50,
                'is_active' => true,
            ]);

            // 4. Create Account (Tenant)
            $account = Account::create([
                'name' => 'Smart Merchant Corp',
                'owner_name' => 'Admin Manager',
                'email' => 'admin@example.com',
                'phone' => '+1234567890',
                'status' => 'Active',
            ]);

            // 5. Create Business, Owner User, Roles, Branch, Fiscal Year, Chart of Accounts, etc.
            $dto = new CreateBusinessDTO(
                accountId: $account->id,
                businessName: 'Smart Merchant Main Business',
                businessType: 'retail',
                primaryPhone: '+1234567890',
                primaryEmail: 'info@smartmerchant.local',
                logoPath: null,
                ownerName: 'Super Admin',
                ownerEmail: 'admin@example.com',
                ownerUsername: 'admin',
                ownerPassword: 'password', // Stored safely inside action
                planId: $plan->id,
                currencyId: $currency->id,
                country: 'US',
                timezone: 'UTC'
            );

            $createBusinessAction->handle($dto);
        });
    }
}
