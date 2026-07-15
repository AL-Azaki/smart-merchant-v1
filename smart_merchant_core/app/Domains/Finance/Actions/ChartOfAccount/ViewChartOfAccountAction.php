<?php

namespace App\Domains\Finance\Actions\ChartOfAccount;

use App\Domains\Finance\DTOs\ViewChartOfAccountDTO;
use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewChartOfAccountAction
{
    public function __construct(private readonly ChartOfAccountRepositoryInterface $repository) {}

    public function handle(ViewChartOfAccountDTO $dto): ChartOfAccount
    {
        $account = $this->repository->findById($dto->accountId);

        if (!$account || $account->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Account not found.");
        }

        return $account;
    }
}
