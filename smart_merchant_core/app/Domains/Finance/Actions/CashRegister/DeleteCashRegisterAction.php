<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeleteCashRegisterAction
{
    public function __construct(private readonly CashRegisterRepositoryInterface $repository) {}

    public function handle(string $cashRegisterId, string $businessId): bool
    {
        $cashRegister = $this->repository->findById($cashRegisterId);

        if (!$cashRegister || $cashRegister->business_id !== $businessId) {
            throw new ModelNotFoundException("Cash register not found.");
        }

        if ($this->repository->isUsedInOperations($cashRegister->id)) {
            throw ValidationException::withMessages([
                'id' => 'Cannot delete a cash register that has been used in operations. Deactivate it instead.'
            ]);
        }

        return $this->repository->delete($cashRegister);
    }
}
