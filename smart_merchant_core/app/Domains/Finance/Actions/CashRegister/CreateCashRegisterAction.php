<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\DTOs\CreateCashRegisterDTO;
use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use Illuminate\Validation\ValidationException;

class CreateCashRegisterAction
{
    public function __construct(private readonly CashRegisterRepositoryInterface $repository) {}

    public function handle(CreateCashRegisterDTO $dto): CashRegister
    {
        $existing = $this->repository->findByName($dto->businessId, $dto->registerName);
        if ($existing) {
            throw ValidationException::withMessages([
                'register_name' => 'A cash register with this name already exists for the business.'
            ]);
        }

        $data = [
            'business_id' => $dto->businessId,
            'branch_id' => $dto->branchId,
            'register_name' => $dto->registerName,
            'is_active' => $dto->isActive,
        ];

        return $this->repository->create($data);
    }
}
