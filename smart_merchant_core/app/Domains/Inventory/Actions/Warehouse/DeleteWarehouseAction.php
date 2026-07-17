<?php

namespace App\Domains\Inventory\Actions\Warehouse;

use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Inventory\Repositories\Contracts\WarehouseRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class DeleteWarehouseAction
{
    public function __construct(private readonly WarehouseRepositoryInterface $repository) {}

    public function handle(Warehouse $warehouse): void
    {
        if ($warehouse->is_default) {
            throw new InventoryDomainException("Cannot delete the default warehouse of a branch.");
        }

        if ($warehouse->inventories()->exists() ||
            $warehouse->transactions()->exists() ||
            $warehouse->transfersFrom()->exists() ||
            $warehouse->transfersTo()->exists() ||
            $warehouse->purchaseInvoiceItems()->exists() ||
            $warehouse->salesInvoiceItems()->exists()
        ) {
            throw new InventoryDomainException("Cannot delete warehouse. It has historical transactions or inventory.");
        }

        $activeCount = Warehouse::where('business_id', $warehouse->business_id)
            ->where('branch_id', $warehouse->branch_id)
            ->where('is_active', true)
            ->where('id', '!=', $warehouse->id)
            ->count();

        if ($activeCount === 0) {
            throw new InventoryDomainException("Cannot delete the last active warehouse of a branch.");
        }

        $this->repository->delete($warehouse);
    }
}
