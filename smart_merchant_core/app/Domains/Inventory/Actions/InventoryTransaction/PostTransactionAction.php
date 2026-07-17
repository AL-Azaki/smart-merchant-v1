<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class PostTransactionAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(InventoryTransaction $transaction, string $userId): InventoryTransaction
    {
        if ($transaction->status !== 'Draft') {
            throw new InventoryDomainException("Only Draft transactions can be posted.");
        }

        if ($transaction->lines()->count() === 0) {
            throw new InventoryDomainException("Cannot post a transaction without lines.");
        }

        return $this->repository->changeStatus($transaction, 'Posted', $userId);
    }
}
