<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;

class CreateInventoryTransactionAction
{
    public function __construct(
        private InventoryTransactionRepositoryInterface $repository
    ) {}

    public function execute(array $data): InventoryTransaction
    {
        $data['status'] = 'Draft';
        return $this->repository->create($data);
    }
}
