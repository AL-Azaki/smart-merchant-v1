<?php

namespace App\Domains\Inventory\Actions\Inventory;

use App\Domains\Inventory\DTOs\Inventory\UpdateInventoryDTO;
use App\Domains\Inventory\Models\Inventory;
use App\Domains\Inventory\Repositories\Contracts\InventoryRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class UpdateInventoryAction
{
    public function __construct(private readonly InventoryRepositoryInterface $repository) {}

    public function handle(Inventory $inventory, UpdateInventoryDTO $dto): Inventory
    {
        if ($dto->alertQuantity !== null && $dto->alertQuantity < 0) {
            throw new InventoryDomainException("Alert quantity cannot be negative.");
        }

        return $this->repository->update($inventory, $dto);
    }
}
