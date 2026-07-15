<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;

class InitializeChartOfAccountsAction
{
    public function __construct(private readonly ChartOfAccountRepositoryInterface $repository) {}

    public function handle(string $businessId): array
    {
        $defaultAccounts = [
            ['business_id' => $businessId, 'account_code' => '1000', 'account_name_ar' => 'الأصول', 'account_name_en' => 'Assets', 'account_type' => 'Asset', 'is_active' => true],
            ['business_id' => $businessId, 'account_code' => '2000', 'account_name_ar' => 'الخصوم', 'account_name_en' => 'Liabilities', 'account_type' => 'Liability', 'is_active' => true],
            ['business_id' => $businessId, 'account_code' => '3000', 'account_name_ar' => 'حقوق الملكية', 'account_name_en' => 'Equity', 'account_type' => 'Equity', 'is_active' => true],
            ['business_id' => $businessId, 'account_code' => '4000', 'account_name_ar' => 'الإيرادات', 'account_name_en' => 'Revenue', 'account_type' => 'Revenue', 'is_active' => true],
            ['business_id' => $businessId, 'account_code' => '5000', 'account_name_ar' => 'المصروفات', 'account_name_en' => 'Expenses', 'account_type' => 'Expense', 'is_active' => true],
        ];

        return $this->repository->createMany($defaultAccounts);
    }
}
