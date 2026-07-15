<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Domains\Finance\Models\AccountType;

class AccountTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $types = [
            [
                'name_en' => 'Assets',
                'name_ar' => 'الأصول',
                'slug' => 'assets',
            ],
            [
                'name_en' => 'Liabilities',
                'name_ar' => 'الخصوم',
                'slug' => 'liabilities',
            ],
            [
                'name_en' => 'Equity',
                'name_ar' => 'حقوق الملكية',
                'slug' => 'equity',
            ],
            [
                'name_en' => 'Revenue',
                'name_ar' => 'الإيرادات',
                'slug' => 'revenue',
            ],
            [
                'name_en' => 'Expenses',
                'name_ar' => 'المصروفات',
                'slug' => 'expenses',
            ],
        ];

        foreach ($types as $type) {
            AccountType::updateOrCreate(
                ['slug' => $type['slug']],
                $type
            );
        }
    }
}
