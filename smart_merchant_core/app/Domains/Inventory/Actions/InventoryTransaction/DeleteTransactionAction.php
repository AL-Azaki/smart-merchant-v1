<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class DeleteTransactionAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(InventoryTransaction $transaction): void
    {
        if ($transaction->status !== 'Draft') {
            throw new InventoryDomainException("Only Draft transactions can be deleted.");
        }

        $this->repository->delete($transaction);
    }
}
