<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use App\Domains\Finance\Models\CashRegister;

class CreateCashRegisterAction
{
    private CashRegisterRepositoryInterface $repository;

    public function __construct(CashRegisterRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $data): CashRegister
    {
        return $this->repository->create($data);
    }
}
