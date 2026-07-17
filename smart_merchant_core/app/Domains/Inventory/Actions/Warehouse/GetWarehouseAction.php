<?php

namespace App\Domains\Inventory\Actions\Warehouse;

use App\Domains\Inventory\Models\Warehouse;
use App\Domains\Inventory\Repositories\Contracts\WarehouseRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class GetWarehouseAction
{
    public function __construct(private readonly WarehouseRepositoryInterface $repository) {}

    public function handle(string $id, string $businessId): Warehouse
    {
        $warehouse = $this->repository->findById($id, ['branch']);

        if (!$warehouse || $warehouse->business_id !== $businessId) {
            throw new ModelNotFoundException("Warehouse not found.");
        }

        return $warehouse;
    }
}
