<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;
use App\Models\User;
use App\Models\Account;
use App\Models\Business;
use App\Models\Branch;
use App\Models\Currency;
use App\Models\Role;
use App\Models\Permission;
use App\Models\Subscription;
use App\Models\Plan;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductUnit;
use App\Models\Unit;

class SmartMerchantSeeder extends Seeder
{
    public function run(): void
    {
        $now = Carbon::now();

        // 1. Account
        $account = Account::create([
            'name' => 'Smart Merchant QA Account',
            'owner_name' => 'QA Admin',
            'email' => 'admin@smartmerchant.com',
            'status' => 'Active',
        ]);

        // 2. Currency
        $currency = Currency::firstOrCreate(
            ['currency_code' => 'YER'],
            [
                'currency_name_en' => 'Yemeni Rial',
                'currency_name_ar' => 'ريال يمني',
                'currency_symbol' => '﷼',
                'exchange_rate' => 1.0,
                'is_base_currency' => true,
                'is_active' => true,
            ]
        );

        // 3. User
        $user = User::firstOrCreate(
            ['email' => 'admin@smartmerchant.com'],
            [
                'full_name' => 'QA Admin',
                'username' => 'qa_admin',
                'password_hash' => Hash::make('admin123'),
                'account_id' => $account->id,
                'is_active' => true,
            ]
        );

        // 4. Business
        $business = Business::create([
            'account_id' => $account->id,
            'business_name' => 'Smart Merchant QA Business',
            'storefront_slug' => 'qa-business',
            'business_type' => 'Retail',
            'status' => 'Active',
        ]);

        // 5. Branch
        $branch = Branch::create([
            'business_id' => $business->id,
            'branch_name' => 'Main QA Branch',
            'branch_code' => 'MAIN-001',
            'is_active' => true,
        ]);

        // 6. User <-> Branch
        DB::table('user_branches')->insert([
            'user_id' => $user->id,
            'branch_id' => $branch->id,
        ]);

        // 7. Plan & Subscription
        $plan = Plan::firstOrCreate(
            ['plan_name' => 'Pro'],
            [
                'price' => 50.00,
                'billing_cycle' => 'Monthly',
                'duration_months' => 1,
                'currency_id' => $currency->id,
                'max_businesses' => 2,
                'max_branches' => 5,
                'max_users' => 10,
                'is_active' => true,
            ]
        );

        Subscription::create([
            'account_id' => $account->id,
            'plan_id' => $plan->id,
            'start_date' => $now,
            'end_date' => $now->copy()->addYear(),
            'amount_paid' => 50.00,
            'status' => 'Active',
        ]);

        // 8. Roles and Permissions
        $role = Role::firstOrCreate([
            'business_id' => $business->id,
            'role_name' => 'Admin',
            'description' => 'QA Admin Role',
            'is_system_role' => true,
        ]);

        $permission = Permission::firstOrCreate([
            'module' => 'Sales',
            'permission_code' => 'sales.create',
            'permission_name' => 'Create Sale',
        ]);
        $permission2 = Permission::firstOrCreate([
            'module' => 'Inventory',
            'permission_code' => 'inventory.view',
            'permission_name' => 'View Inventory',
        ]);
        
        DB::table('role_permissions')->insertOrIgnore([
            ['role_id' => $role->id, 'permission_id' => $permission->id],
            ['role_id' => $role->id, 'permission_id' => $permission2->id],
        ]);

        DB::table('user_roles')->insert([
            'user_id' => $user->id,
            'role_id' => $role->id,
        ]);

        // 9. Categories, Units, Products
        $categoryId = Str::uuid()->toString();
        DB::table('categories')->insert([
            'id' => $categoryId,
            'business_id' => $business->id,
            'category_name' => 'Electronics',
            'category_code' => 'ELEC',
            'is_active' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $unitId = Str::uuid()->toString();
        DB::table('units')->insert([
            'id' => $unitId,
            'business_id' => $business->id,
            'unit_name' => 'Piece',
            'unit_symbol' => 'PCS',
            'is_active' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $productId = Str::uuid()->toString();
        DB::table('products')->insert([
            'id' => $productId,
            'business_id' => $business->id,
            'category_id' => $categoryId,
            'product_type' => 'standard',
            'product_name' => 'Test Smartphone',
            'product_code' => 'TEST-001',
            'description' => 'A QA test product.',
            'is_active' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $productUnitId = Str::uuid()->toString();
        DB::table('product_units')->insert([
            'id' => $productUnitId,
            'business_id' => $business->id,
            'product_id' => $productId,
            'unit_id' => $unitId,
            'sku' => 'TEST-001-PCS',
            'barcode' => '1234567890123',
            'conversion_factor' => 1.0,
            'is_base_unit' => true,
            'selling_price' => 500.0,
            'purchase_price' => 250.0,
            'is_active' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
        
        $this->command->info('SmartMerchantSeeder: QA Account generated with email: admin@smartmerchant.com and password: admin123');
    }
}
