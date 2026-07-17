<?php

namespace App\Domains\Inventory\Actions\Inventory;

use App\Domains\Inventory\Models\Inventory;
use App\Domains\Inventory\Repositories\Contracts\InventoryRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class DeleteInventoryAction
{
    public function __construct(private readonly InventoryRepositoryInterface $repository) {}

    public function handle(Inventory $inventory): void
    {
        if ($inventory->quantity > 0) {
            throw new InventoryDomainException("Cannot delete inventory record with a positive balance.");
        }

        $this->repository->delete($inventory);
    }
}
