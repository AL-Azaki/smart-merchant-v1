<?php

namespace App\Domains\Finance\Actions\ChartOfAccount;

use App\Domains\Finance\DTOs\ChartOfAccountListCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListChartOfAccountsAction
{
    public function __construct(private readonly ChartOfAccountRepositoryInterface $repository) {}

    public function handle(ChartOfAccountListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
