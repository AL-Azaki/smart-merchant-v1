<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use App\Domains\Finance\Models\CashRegister;

class UpdateCashRegisterAction
{
    private CashRegisterRepositoryInterface $repository;

    public function __construct(CashRegisterRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data): CashRegister
    {
        return $this->repository->update($id, $data);
    }
}
