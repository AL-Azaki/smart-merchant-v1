<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\DTOs\InventoryTransaction\CreateTransactionDTO;
use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class CreateTransactionAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(CreateTransactionDTO $dto): InventoryTransaction
    {
        $warehouse = Warehouse::find($dto->warehouseId);
        if (!$warehouse || $warehouse->business_id !== $dto->businessId || $warehouse->branch_id !== $dto->branchId) {
            throw new InventoryDomainException("Warehouse does not exist or does not belong to this branch.");
        }

        return $this->repository->create($dto->toArray());
    }
}
