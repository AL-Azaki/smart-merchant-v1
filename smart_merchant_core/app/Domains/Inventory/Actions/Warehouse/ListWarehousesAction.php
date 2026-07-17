<?php

namespace App\Domains\Inventory\Actions\Warehouse;

use App\Domains\Inventory\DTOs\Warehouse\WarehouseCriteriaDTO;
use App\Domains\Inventory\Repositories\Contracts\WarehouseRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListWarehousesAction
{
    public function __construct(private readonly WarehouseRepositoryInterface $repository) {}

    public function handle(WarehouseCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
