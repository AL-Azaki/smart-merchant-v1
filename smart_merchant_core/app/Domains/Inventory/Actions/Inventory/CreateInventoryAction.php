<?php

namespace App\Domains\Inventory\Actions\Inventory;

use App\Domains\Inventory\DTOs\Inventory\CreateInventoryDTO;
use App\Domains\Inventory\Models\Inventory;
use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Inventory\Repositories\Contracts\InventoryRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class CreateInventoryAction
{
    public function __construct(private readonly InventoryRepositoryInterface $repository) {}

    public function handle(CreateInventoryDTO $dto): Inventory
    {
        $warehouse = Warehouse::find($dto->warehouseId);
        if (!$warehouse || $warehouse->business_id !== $dto->businessId) {
            throw new InventoryDomainException("Warehouse does not exist or does not belong to this business.");
        }

        $unit = ProductUnit::find($dto->productUnitId);
        if (!$unit || $unit->business_id !== $dto->businessId) {
            throw new InventoryDomainException("Product unit does not exist or does not belong to this business.");
        }

        if ($this->repository->exists($dto->businessId, $dto->warehouseId, $dto->productUnitId)) {
            throw new InventoryDomainException("Inventory record already exists for this warehouse and product unit.");
        }

        if ($dto->quantity < 0 || $dto->averageCost < 0 || $dto->alertQuantity < 0) {
            throw new InventoryDomainException("Quantity and cost values cannot be negative.");
        }

        return $this->repository->create($dto->toArray());
    }
}
