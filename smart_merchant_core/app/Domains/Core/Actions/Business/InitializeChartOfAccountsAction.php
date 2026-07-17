<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;

class InitializeChartOfAccountsAction
{
    public function __construct(private readonly ChartOfAccountRepositoryInterface $repository) {}

    public function handle(string $businessId): array
    {
        $assetType = \App\Domains\Finance\Models\AccountType::where('slug', 'assets')->first();
        $liabilityType = \App\Domains\Finance\Models\AccountType::where('slug', 'liabilities')->first();
        $equityType = \App\Domains\Finance\Models\AccountType::where('slug', 'equity')->first();
        $revenueType = \App\Domains\Finance\Models\AccountType::where('slug', 'revenue')->first();
        $expenseType = \App\Domains\Finance\Models\AccountType::where('slug', 'expenses')->first();

        $defaultAccounts = [
            ['business_id' => $businessId, 'account_code' => '1000', 'account_name' => 'Assets', 'account_type_id' => $assetType->id, 'normal_balance' => 'Debit', 'is_active' => true],
            ['business_id' => $businessId, 'account_code' => '2000', 'account_name' => 'Liabilities', 'account_type_id' => $liabilityType->id, 'normal_balance' => 'Credit', 'is_active' => true],
            ['business_id' => $businessId, 'account_code' => '3000', 'account_name' => 'Equity', 'account_type_id' => $equityType->id, 'normal_balance' => 'Credit', 'is_active' => true],
            ['business_id' => $businessId, 'account_code' => '4000', 'account_name' => 'Revenue', 'account_type_id' => $revenueType->id, 'normal_balance' => 'Credit', 'is_active' => true],
            ['business_id' => $businessId, 'account_code' => '5000', 'account_name' => 'Expenses', 'account_type_id' => $expenseType->id, 'normal_balance' => 'Debit', 'is_active' => true],
        ];

        return $this->repository->createMany($defaultAccounts);
    }
}
