<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use Illuminate\Support\Collection;

class ListInventoryTransactionsAction
{
    public function __construct(
        private InventoryTransactionRepositoryInterface $repository
    ) {}

    public function execute(string $businessId): Collection
    {
        return $this->repository->getAll($businessId);
    }
}
