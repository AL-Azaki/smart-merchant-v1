<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use Illuminate\Support\Collection;

class ListCashRegistersAction
{
    private CashRegisterRepositoryInterface $repository;

    public function __construct(CashRegisterRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $filters = []): Collection
    {
        return $this->repository->list($filters);
    }
}
