<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use Exception;

class UpdateInventoryTransactionAction
{
    public function __construct(
        private InventoryTransactionRepositoryInterface $repository
    ) {}

    public function execute(InventoryTransaction $transaction, array $data): InventoryTransaction
    {
        if ($transaction->status !== 'Draft') {
            throw new Exception("Cannot update an inventory transaction that is not in Draft status.");
        }

        return $this->repository->update($transaction, $data);
    }
}
