<?php

namespace App\Domains\Finance\Actions\FiscalPeriod;

use App\Domains\Finance\DTOs\FiscalPeriodListCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListFiscalPeriodsAction
{
    public function __construct(private readonly FiscalPeriodRepositoryInterface $repository) {}

    public function handle(FiscalPeriodListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
