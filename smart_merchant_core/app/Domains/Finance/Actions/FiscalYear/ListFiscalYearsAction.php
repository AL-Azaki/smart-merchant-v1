<?php

namespace App\Domains\Finance\Actions\FiscalYear;

use App\Domains\Finance\DTOs\FiscalYearListCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListFiscalYearsAction
{
    public function __construct(private readonly FiscalYearRepositoryInterface $repository) {}

    public function handle(FiscalYearListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
