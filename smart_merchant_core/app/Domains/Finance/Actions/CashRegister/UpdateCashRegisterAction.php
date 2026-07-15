<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\DTOs\UpdateCashRegisterDTO;
use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class UpdateCashRegisterAction
{
    public function __construct(private readonly CashRegisterRepositoryInterface $repository) {}

    public function handle(UpdateCashRegisterDTO $dto): CashRegister
    {
        $cashRegister = $this->repository->findById($dto->cashRegisterId);

        if (!$cashRegister || $cashRegister->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Cash register not found.");
        }

        if ($this->repository->isUsedInOperations($cashRegister->id)) {
            // Cannot change branch or name if used, though name might be allowed in some systems,
            // V1 requires immutable binding data. We'll strict check.
            if ($cashRegister->branch_id !== $dto->branchId) {
                throw ValidationException::withMessages([
                    'branch_id' => 'Cannot change the branch of a cash register that has been used in operations.'
                ]);
            }
        }

        if ($cashRegister->register_name !== $dto->registerName) {
            $existing = $this->repository->findByName($dto->businessId, $dto->registerName);
            if ($existing && $existing->id !== $cashRegister->id) {
                throw ValidationException::withMessages([
                    'register_name' => 'A cash register with this name already exists for the business.'
                ]);
            }
        }

        $data = [
            'branch_id' => $dto->branchId,
            'register_name' => $dto->registerName,
        ];

        return $this->repository->update($cashRegister, $data);
    }
}
