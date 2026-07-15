<?php

namespace App\Domains\Finance\Actions\ChartOfAccount;

use App\Domains\Finance\DTOs\ChartOfAccountSearchCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchChartOfAccountsAction
{
    public function __construct(private readonly ChartOfAccountRepositoryInterface $repository) {}

    public function handle(ChartOfAccountSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
