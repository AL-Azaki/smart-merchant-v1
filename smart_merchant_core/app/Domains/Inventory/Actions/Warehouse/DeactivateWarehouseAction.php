<?php

namespace App\Domains\Inventory\Actions\Warehouse;

use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Inventory\Repositories\Contracts\WarehouseRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class DeactivateWarehouseAction
{
    public function __construct(private readonly WarehouseRepositoryInterface $repository) {}

    public function handle(Warehouse $warehouse): Warehouse
    {
        if ($warehouse->is_default) {
            throw new InventoryDomainException("Cannot deactivate the default warehouse.");
        }

        $activeCount = Warehouse::where('business_id', $warehouse->business_id)
            ->where('branch_id', $warehouse->branch_id)
            ->where('is_active', true)
            ->where('id', '!=', $warehouse->id)
            ->count();

        if ($activeCount === 0) {
            throw new InventoryDomainException("Cannot deactivate the last active warehouse of a branch.");
        }

        return $this->repository->updateStatus($warehouse, false);
    }
}
