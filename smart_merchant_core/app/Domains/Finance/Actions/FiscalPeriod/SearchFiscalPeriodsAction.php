<?php

namespace App\Domains\Finance\Actions\FiscalPeriod;

use App\Domains\Finance\DTOs\FiscalPeriodSearchCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchFiscalPeriodsAction
{
    public function __construct(private readonly FiscalPeriodRepositoryInterface $repository) {}

    public function handle(FiscalPeriodSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
