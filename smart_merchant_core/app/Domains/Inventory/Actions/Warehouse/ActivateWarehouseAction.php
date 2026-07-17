<?php

namespace App\Domains\Inventory\Actions\Warehouse;

use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Inventory\Repositories\Contracts\WarehouseRepositoryInterface;

class ActivateWarehouseAction
{
    public function __construct(private readonly WarehouseRepositoryInterface $repository) {}

    public function handle(Warehouse $warehouse): Warehouse
    {
        return $this->repository->updateStatus($warehouse, true);
    }
}
