<?php

namespace App\Domains\Inventory\Actions\Warehouse;

use App\Domains\Inventory\DTOs\Warehouse\UpdateWarehouseDTO;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Core\Models\Branch;
use App\Domains\Inventory\Repositories\Contracts\WarehouseRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class UpdateWarehouseAction
{
    public function __construct(private readonly WarehouseRepositoryInterface $repository) {}

    public function handle(Warehouse $warehouse, UpdateWarehouseDTO $dto): Warehouse
    {
        if ($dto->warehouseCode !== null && $dto->warehouseCode !== $warehouse->warehouse_code) {
            if ($this->repository->existsByCode($dto->warehouseCode, $warehouse->business_id)) {
                throw new InventoryDomainException("Warehouse code '{$dto->warehouseCode}' already exists.");
            }
        }

        if ($dto->branchId !== null && $dto->branchId !== $warehouse->branch_id) {
            $branch = Branch::find($dto->branchId);
            if (!$branch || $branch->business_id !== $warehouse->business_id) {
                throw new InventoryDomainException("Branch does not exist or does not belong to this business.");
            }
        }

        $branchId = $dto->branchId ?? $warehouse->branch_id;

        if ($dto->isDefault === true && !$warehouse->is_default) {
            $this->repository->unsetDefaultWarehouse($warehouse->business_id, $branchId);
        }
        
        if ($dto->isDefault === false && $warehouse->is_default) {
            throw new InventoryDomainException("Cannot unset the default warehouse. You must set another warehouse as default instead.");
        }

        return $this->repository->update($warehouse, $dto);
    }
}
