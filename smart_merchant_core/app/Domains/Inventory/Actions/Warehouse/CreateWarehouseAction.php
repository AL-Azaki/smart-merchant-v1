<?php

namespace App\Domains\Inventory\Actions\Warehouse;

use App\Domains\Inventory\DTOs\Warehouse\CreateWarehouseDTO;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Core\Models\Branch;
use App\Domains\Inventory\Repositories\Contracts\WarehouseRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class CreateWarehouseAction
{
    public function __construct(private readonly WarehouseRepositoryInterface $repository) {}

    public function handle(CreateWarehouseDTO $dto): Warehouse
    {
        $branch = Branch::find($dto->branchId);
        if (!$branch || $branch->business_id !== $dto->businessId) {
            throw new InventoryDomainException("Branch does not exist or does not belong to this business.");
        }

        if ($this->repository->existsByCode($dto->warehouseCode, $dto->businessId)) {
            throw new InventoryDomainException("Warehouse code '{$dto->warehouseCode}' already exists.");
        }

        if ($dto->isDefault) {
            $this->repository->unsetDefaultWarehouse($dto->businessId, $dto->branchId);
        } else {
            if (!$this->repository->hasDefaultWarehouse($dto->businessId, $dto->branchId)) {
                $dto = new CreateWarehouseDTO(
                    businessId: $dto->businessId,
                    branchId: $dto->branchId,
                    warehouseName: $dto->warehouseName,
                    warehouseCode: $dto->warehouseCode,
                    address: $dto->address,
                    isDefault: true,
                    isActive: $dto->isActive
                );
            }
        }

        return $this->repository->create($dto->toArray());
    }
}
