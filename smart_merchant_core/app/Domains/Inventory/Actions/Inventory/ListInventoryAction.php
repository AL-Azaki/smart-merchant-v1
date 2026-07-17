<?php

namespace App\Domains\Inventory\Actions\Inventory;

use App\Domains\Inventory\DTOs\Inventory\InventoryCriteriaDTO;
use App\Domains\Inventory\Repositories\Contracts\InventoryRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListInventoryAction
{
    public function __construct(private readonly InventoryRepositoryInterface $repository) {}

    public function handle(InventoryCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
