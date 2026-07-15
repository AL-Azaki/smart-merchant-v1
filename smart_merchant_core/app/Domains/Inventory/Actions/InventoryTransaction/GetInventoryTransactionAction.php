<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;

class GetInventoryTransactionAction
{
    public function __construct(
        private InventoryTransactionRepositoryInterface $repository
    ) {}

    public function execute(string $businessId, string $id): ?InventoryTransaction
    {
        return $this->repository->findById($businessId, $id);
    }
}
