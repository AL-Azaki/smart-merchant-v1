<?php

namespace App\Domains\Inventory\Repositories\Contracts;

use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Inventory\DTOs\Warehouse\WarehouseCriteriaDTO;
use App\Domains\Inventory\DTOs\Warehouse\UpdateWarehouseDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface WarehouseRepositoryInterface
{
    public function create(array $data): Warehouse;

    public function findById(string $id, array $with = []): ?Warehouse;

    public function existsByCode(string $code, string $businessId): bool;

    public function hasDefaultWarehouse(string $businessId, string $branchId): bool;

    public function unsetDefaultWarehouse(string $businessId, string $branchId): void;

    public function search(WarehouseCriteriaDTO $criteria): LengthAwarePaginator;

    public function update(Warehouse $warehouse, UpdateWarehouseDTO $dto): Warehouse;

    public function delete(Warehouse $warehouse): bool;

    public function updateStatus(Warehouse $warehouse, bool $isActive): Warehouse;
}
