<?php

namespace App\Domains\Inventory\Repositories\Eloquent;

use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Inventory\Repositories\Contracts\WarehouseRepositoryInterface;
use App\Domains\Inventory\DTOs\Warehouse\WarehouseCriteriaDTO;
use App\Domains\Inventory\DTOs\Warehouse\UpdateWarehouseDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class WarehouseEloquentRepository implements WarehouseRepositoryInterface
{
    public function create(array $data): Warehouse
    {
        return Warehouse::create($data);
    }

    public function findById(string $id, array $with = []): ?Warehouse
    {
        return Warehouse::with($with)->find($id);
    }

    public function existsByCode(string $code, string $businessId): bool
    {
        return Warehouse::where('warehouse_code', strtoupper($code))->where('business_id', $businessId)->exists();
    }

    public function hasDefaultWarehouse(string $businessId, string $branchId): bool
    {
        return Warehouse::where('business_id', $businessId)
            ->where('branch_id', $branchId)
            ->where('is_default', true)
            ->exists();
    }

    public function unsetDefaultWarehouse(string $businessId, string $branchId): void
    {
        Warehouse::where('business_id', $businessId)
            ->where('branch_id', $branchId)
            ->update(['is_default' => false]);
    }

    public function search(WarehouseCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Warehouse::with('branch')
            ->where('business_id', $criteria->businessId);

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('warehouse_name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('warehouse_code', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->branchId !== null) {
            $query->where('branch_id', $criteria->branchId);
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                      ->paginate($criteria->perPage);
    }

    public function update(Warehouse $warehouse, UpdateWarehouseDTO $dto): Warehouse
    {
        $warehouse->update($dto->toArray());
        return $warehouse;
    }

    public function delete(Warehouse $warehouse): bool
    {
        return (bool) $warehouse->delete();
    }

    public function updateStatus(Warehouse $warehouse, bool $isActive): Warehouse
    {
        $warehouse->update(['is_active' => $isActive]);
        return $warehouse;
    }
}
