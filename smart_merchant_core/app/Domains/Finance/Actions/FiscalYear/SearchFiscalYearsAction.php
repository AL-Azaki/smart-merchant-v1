<?php

namespace App\Domains\Finance\Actions\FiscalYear;

use App\Domains\Finance\DTOs\FiscalYearSearchCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchFiscalYearsAction
{
    public function __construct(private readonly FiscalYearRepositoryInterface $repository) {}

    public function handle(FiscalYearSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
