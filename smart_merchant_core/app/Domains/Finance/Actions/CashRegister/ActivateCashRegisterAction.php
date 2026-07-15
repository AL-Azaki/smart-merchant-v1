<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ActivateCashRegisterAction
{
    public function __construct(private readonly CashRegisterRepositoryInterface $repository) {}

    public function handle(string $cashRegisterId, string $businessId): CashRegister
    {
        $cashRegister = $this->repository->findById($cashRegisterId);

        if (!$cashRegister || $cashRegister->business_id !== $businessId) {
            throw new ModelNotFoundException("Cash register not found.");
        }

        return $this->repository->update($cashRegister, ['is_active' => true]);
    }
}
