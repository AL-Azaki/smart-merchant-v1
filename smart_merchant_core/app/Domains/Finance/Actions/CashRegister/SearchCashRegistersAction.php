<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\DTOs\CashRegisterSearchCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SearchCashRegistersAction
{
    public function __construct(private readonly CashRegisterRepositoryInterface $repository) {}

    public function handle(CashRegisterSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
