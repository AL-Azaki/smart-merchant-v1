<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\DTOs\CashRegisterListCriteriaDTO;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListCashRegistersAction
{
    public function __construct(private readonly CashRegisterRepositoryInterface $repository) {}

    public function handle(CashRegisterListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->paginate($criteria);
    }
}
