<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\DTOs\ViewCashRegisterDTO;
use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewCashRegisterAction
{
    public function __construct(private readonly CashRegisterRepositoryInterface $repository) {}

    public function handle(ViewCashRegisterDTO $dto): CashRegister
    {
        $cashRegister = $this->repository->findById($dto->cashRegisterId);

        if (!$cashRegister || $cashRegister->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Cash register not found.");
        }

        return $cashRegister;
    }
}
