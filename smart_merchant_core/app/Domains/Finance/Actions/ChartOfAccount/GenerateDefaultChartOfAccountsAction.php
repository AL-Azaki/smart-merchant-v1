<?php

namespace App\Domains\Finance\Actions\ChartOfAccount;

use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use App\Domains\Finance\Repositories\Contracts\AccountTypeRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;

class GenerateDefaultChartOfAccountsAction
{
    public function __construct(
        private readonly ChartOfAccountRepositoryInterface $repository,
        private readonly AccountTypeRepositoryInterface $accountTypeRepository
    ) {}

    public function handle(string $businessId): void
    {
        // Internal Action: Generates default system root accounts for a new business.
        // Should only be called when the business is created.

        if ($this->repository->countRootAccounts($businessId) > 0) {
            return; // Default chart already exists
        }

        $accountTypes = $this->accountTypeRepository->getAllActive()->keyBy('slug');

        if ($accountTypes->isEmpty()) {
            throw new Exception("Account types are not seeded. Cannot generate default chart.");
        }

        DB::transaction(function () use ($businessId, $accountTypes) {
            $defaultAccounts = [
                [
                    'business_id' => $businessId,
                    'account_type_id' => $accountTypes['assets']->id,
                    'account_name' => 'Assets',
                    'normal_balance' => 'Debit',
                    'allow_posting' => false,
                    'is_system' => true,
                    'account_level' => 1,
                    'account_code' => '1000',
                ],
                [
                    'business_id' => $businessId,
                    'account_type_id' => $accountTypes['liabilities']->id,
                    'account_name' => 'Liabilities',
                    'normal_balance' => 'Credit',
                    'allow_posting' => false,
                    'is_system' => true,
                    'account_level' => 1,
                    'account_code' => '2000',
                ],
                [
                    'business_id' => $businessId,
                    'account_type_id' => $accountTypes['equity']->id,
                    'account_name' => 'Equity',
                    'normal_balance' => 'Credit',
                    'allow_posting' => false,
                    'is_system' => true,
                    'account_level' => 1,
                    'account_code' => '3000',
                ],
                [
                    'business_id' => $businessId,
                    'account_type_id' => $accountTypes['revenue']->id,
                    'account_name' => 'Revenue',
                    'normal_balance' => 'Credit',
                    'allow_posting' => false,
                    'is_system' => true,
                    'account_level' => 1,
                    'account_code' => '4000',
                ],
                [
                    'business_id' => $businessId,
                    'account_type_id' => $accountTypes['expenses']->id,
                    'account_name' => 'Expenses',
                    'normal_balance' => 'Debit',
                    'allow_posting' => false,
                    'is_system' => true,
                    'account_level' => 1,
                    'account_code' => '5000',
                ],
            ];

            foreach ($defaultAccounts as $data) {
                $this->repository->create($data);
            }
        });
    }
}
