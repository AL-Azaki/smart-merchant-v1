<?php

namespace App\Domains\Finance\Actions\ChartOfAccount;

use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeactivateChartOfAccountAction
{
    public function __construct(private readonly ChartOfAccountRepositoryInterface $repository) {}

    public function handle(string $accountId, string $businessId): ChartOfAccount
    {
        $account = $this->repository->findById($accountId);

        if (!$account || $account->business_id !== $businessId) {
            throw new ModelNotFoundException("Account not found.");
        }

        return $this->repository->update($account, ['is_active' => false]);
    }
}
