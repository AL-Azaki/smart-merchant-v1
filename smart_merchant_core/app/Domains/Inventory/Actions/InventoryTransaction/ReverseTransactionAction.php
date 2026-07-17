<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class ReverseTransactionAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(InventoryTransaction $transaction, string $userId): InventoryTransaction
    {
        if ($transaction->status !== 'Posted') {
            throw new InventoryDomainException("Only Posted transactions can be reversed.");
        }

        return $this->repository->changeStatus($transaction, 'Reversed', $userId);
    }
}
