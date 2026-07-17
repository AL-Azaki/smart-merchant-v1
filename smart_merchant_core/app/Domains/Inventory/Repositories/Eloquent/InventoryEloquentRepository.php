<?php

namespace App\Domains\Inventory\Repositories\Eloquent;

use App\Domains\Inventory\Models\Inventory;
use App\Domains\Inventory\Repositories\Contracts\InventoryRepositoryInterface;
use App\Domains\Inventory\DTOs\Inventory\InventoryCriteriaDTO;
use App\Domains\Inventory\DTOs\Inventory\UpdateInventoryDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class InventoryEloquentRepository implements InventoryRepositoryInterface
{
    public function create(array $data): Inventory
    {
        return Inventory::create($data);
    }

    public function findById(string $id, array $with = []): ?Inventory
    {
        return Inventory::with($with)->find($id);
    }

    public function exists(string $businessId, string $warehouseId, string $productUnitId): bool
    {
        return Inventory::where('business_id', $businessId)
            ->where('warehouse_id', $warehouseId)
            ->where('product_unit_id', $productUnitId)
            ->exists();
    }

    public function search(InventoryCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Inventory::with(['warehouse', 'productUnit'])
            ->where('business_id', $criteria->businessId);

        if ($criteria->warehouseId !== null) {
            $query->where('warehouse_id', $criteria->warehouseId);
        }

        if ($criteria->productUnitId !== null) {
            $query->where('product_unit_id', $criteria->productUnitId);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                      ->paginate($criteria->perPage);
    }

    public function update(Inventory $inventory, UpdateInventoryDTO $dto): Inventory
    {
        $inventory->update($dto->toArray());
        return $inventory;
    }

    public function delete(Inventory $inventory): bool
    {
        return (bool) $inventory->delete();
    }
}
