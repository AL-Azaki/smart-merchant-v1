<?php

namespace App\Domains\Inventory\Actions\Inventory;

use App\Domains\Inventory\Models\Inventory;
use App\Domains\Inventory\Repositories\Contracts\InventoryRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class GetInventoryAction
{
    public function __construct(private readonly InventoryRepositoryInterface $repository) {}

    public function handle(string $id, string $businessId): Inventory
    {
        $inventory = $this->repository->findById($id, ['warehouse', 'productUnit']);

        if (!$inventory || $inventory->business_id !== $businessId) {
            throw new ModelNotFoundException("Inventory not found.");
        }

        return $inventory;
    }
}
