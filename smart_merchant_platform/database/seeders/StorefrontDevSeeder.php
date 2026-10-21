<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use App\Models\Account;
use App\Models\Business;
use App\Models\Branch;
use App\Models\Channel;
use App\Models\Currency;
use App\Models\Category;
use App\Models\Product;
use App\Models\Unit;
use App\Models\ProductUnit;
use App\Models\InventoryProjection;

class StorefrontDevSeeder extends Seeder
{
    /**
     * Run the database seeds.
     * Idempotent seeder strictly intended for local/testing development.
     */
    public function run(): void
    {
        if (app()->environment('production')) {
            $this->command?->warn('StorefrontDevSeeder: Refusing to seed in production environment.');
            return;
        }

        // 1. Currency
        $currency = Currency::firstOrCreate(
            ['currency_code' => 'YER'],
            [
                'currency_name_ar' => 'ريال يمني',
                'currency_name_en' => 'Yemeni Rial',
                'currency_symbol' => 'ر.ي',
                'decimal_places' => 2,
                'exchange_rate' => 1.0,
                'is_base_currency' => true,
                'is_active' => true,
            ]
        );

        // 2. Account
        $account = Account::firstOrCreate(
            ['email' => 'test-storefront-owner@example.com'],
            [
                'name' => 'TEST Storefront Account',
                'owner_name' => 'Storefront Owner',
                'status' => 'Active',
            ]
        );

        // 3. Business (storefront_slug = integration-test-store)
        $business = Business::withTrashed()->where('storefront_slug', 'integration-test-store')->first();
        if ($business) {
            if ($business->trashed()) {
                $business->restore();
            }
            $business->update([
                'account_id' => $account->id,
                'business_name' => 'TEST Business E2E',
                'storefront_display_name' => 'متجر الاختبار التكاملي',
                'storefront_active' => true,
                'storefront_phone' => '967770000111',
                'storefront_whatsapp' => '967770000111',
                'storefront_address_text' => 'صنعاء - شارع الستين',
                'status' => 'Active',
            ]);
        } else {
            $business = Business::create([
                'id' => (string) Str::uuid(),
                'account_id' => $account->id,
                'business_name' => 'TEST Business E2E',
                'storefront_slug' => 'integration-test-store',
                'storefront_display_name' => 'متجر الاختبار التكاملي',
                'storefront_active' => true,
                'storefront_phone' => '967770000111',
                'storefront_whatsapp' => '967770000111',
                'storefront_address_text' => 'صنعاء - شارع الستين',
                'status' => 'Active',
            ]);
        }

        // 4. Branch
        $branch = Branch::firstOrCreate(
            [
                'business_id' => $business->id,
                'branch_code' => 'ONLINE-01',
            ],
            [
                'id' => (string) Str::uuid(),
                'branch_name' => 'Online Branch Test',
                'is_online_branch' => true,
                'is_active' => true,
            ]
        );

        // 4b. User (admin login for real device testing)
        $user = \App\Models\User::firstOrCreate(
            ['email' => 'admin@smartmerchant.com'],
            [
                'id' => (string) Str::uuid(),
                'account_id' => $account->id,
                'username' => 'admin',
                'full_name' => 'المدير العام',
                'phone' => '967770000111',
                'password_hash' => \Illuminate\Support\Facades\Hash::make('password123'),
                'is_active' => true,
            ]
        );
        \Illuminate\Support\Facades\DB::table('user_branches')->updateOrInsert(
            ['user_id' => $user->id, 'branch_id' => $branch->id],
            ['is_active' => true, 'assigned_at' => now()]
        );
        $user->update(['default_branch_id' => $branch->id]);

        // 5. Channel
        $channel = Channel::firstOrCreate(
            [
                'business_id' => $business->id,
                'channel_code' => 'ONLINE-STORE-01',
            ],
            [
                'id' => (string) Str::uuid(),
                'channel_name' => 'Online Store',
                'channel_type' => 'Ecommerce',
                'is_active' => true,
            ]
        );

        // 6. Unit
        $unit = Unit::firstOrCreate(
            [
                'business_id' => $business->id,
                'unit_name' => 'حبة',
            ],
            [
                'id' => (string) Str::uuid(),
                'unit_symbol' => 'حبة',
                'is_active' => true,
            ]
        );

        // 7. Category
        $category = Category::firstOrCreate(
            [
                'business_id' => $business->id,
                'category_code' => 'TEST-CAT',
            ],
            [
                'id' => (string) Str::uuid(),
                'category_name' => 'فئة الاختبار التكاملي',
                'is_active' => true,
            ]
        );

        // 8. Products
        $product1 = Product::firstOrCreate(
            [
                'business_id' => $business->id,
                'product_code' => 'TEST-PROD-001',
            ],
            [
                'id' => (string) Str::uuid(),
                'category_id' => $category->id,
                'product_name' => 'منتج الاختبار التكاملي الفاخر',
                'description' => 'وصف منتج الاختبار التكاملي لمتجر Next.js عالي الجودة والأداء.',
                'is_active' => true,
                'show_in_store' => true,
            ]
        );
        $product1->update(['show_in_store' => true, 'is_active' => true]);

        $productUnit1 = ProductUnit::firstOrCreate(
            [
                'business_id' => $business->id,
                'product_id' => $product1->id,
                'sku' => 'TEST-PROD-001-UNIT',
            ],
            [
                'id' => (string) Str::uuid(),
                'unit_id' => $unit->id,
                'selling_price' => 1250.00,
                'conversion_factor' => 1.0,
                'is_base_unit' => true,
                'is_active' => true,
            ]
        );
        $productUnit1->update(['is_active' => true, 'selling_price' => 1250.00]);

        InventoryProjection::updateOrCreate(
            [
                'business_id' => $business->id,
                'branch_id' => $branch->id,
                'product_unit_id' => $productUnit1->id,
            ],
            [
                'quantity' => 100,
                'revision' => 1,
            ]
        );

        // Second product
        $product2 = Product::firstOrCreate(
            [
                'business_id' => $business->id,
                'product_code' => 'TEST-PROD-002',
            ],
            [
                'id' => (string) Str::uuid(),
                'category_id' => $category->id,
                'product_name' => 'سماعات رأس لاسلكية احترافية',
                'description' => 'سماعات لاسلكية مع ميزة عزل الضوضاء النشط وجودة صوتية نقية.',
                'is_active' => true,
                'show_in_store' => true,
            ]
        );
        $product2->update(['show_in_store' => true, 'is_active' => true]);

        $productUnit2 = ProductUnit::firstOrCreate(
            [
                'business_id' => $business->id,
                'product_id' => $product2->id,
                'sku' => 'TEST-PROD-002-UNIT',
            ],
            [
                'id' => (string) Str::uuid(),
                'unit_id' => $unit->id,
                'selling_price' => 3800.00,
                'conversion_factor' => 1.0,
                'is_base_unit' => true,
                'is_active' => true,
            ]
        );
        $productUnit2->update(['is_active' => true, 'selling_price' => 3800.00]);

        InventoryProjection::updateOrCreate(
            [
                'business_id' => $business->id,
                'branch_id' => $branch->id,
                'product_unit_id' => $productUnit2->id,
            ],
            [
                'quantity' => 50,
                'revision' => 1,
            ]
        );

        if ($this->command) {
            $this->command->info("StorefrontDevSeeder completed successfully:");
            $this->command->info("- Business ID: {$business->id}");
            $this->command->info("- Storefront Slug: {$business->storefront_slug}");
            $this->command->info("- Active: " . ($business->storefront_active ? 'true' : 'false'));
            $this->command->info("- Product 1 ID: {$product1->id} (Unit: {$productUnit1->id}, Price: 1250.00)");
            $this->command->info("- Product 2 ID: {$product2->id} (Unit: {$productUnit2->id}, Price: 3800.00)");
        }
    }
}
