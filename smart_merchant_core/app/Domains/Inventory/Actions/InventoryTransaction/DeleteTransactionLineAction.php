<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Models\InventoryTransactionLine;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class DeleteTransactionLineAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(InventoryTransaction $transaction, InventoryTransactionLine $line): void
    {
        if ($transaction->status !== 'Draft') {
            throw new InventoryDomainException("Lines can only be deleted from Draft transactions.");
        }

        if ($line->inventory_transaction_id !== $transaction->id) {
            throw new InventoryDomainException("Line does not belong to this transaction.");
        }

        $this->repository->removeLine($line);
    }
}
