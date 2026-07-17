<?php

namespace App\Domains\Inventory\Repositories\Contracts;

use App\Domains\Inventory\Models\Inventory;
use App\Domains\Inventory\DTOs\Inventory\InventoryCriteriaDTO;
use App\Domains\Inventory\DTOs\Inventory\UpdateInventoryDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface InventoryRepositoryInterface
{
    public function create(array $data): Inventory;

    public function findById(string $id, array $with = []): ?Inventory;

    public function exists(string $businessId, string $warehouseId, string $productUnitId): bool;

    public function search(InventoryCriteriaDTO $criteria): LengthAwarePaginator;

    public function update(Inventory $inventory, UpdateInventoryDTO $dto): Inventory;

    public function delete(Inventory $inventory): bool;
}
