<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\DTOs\InventoryTransaction\TransactionLineDTO;
use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Models\InventoryTransactionLine;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class UpdateTransactionLineAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(InventoryTransaction $transaction, InventoryTransactionLine $line, TransactionLineDTO $dto): InventoryTransactionLine
    {
        if ($transaction->status !== 'Draft') {
            throw new InventoryDomainException("Lines can only be updated in Draft transactions.");
        }

        if ($line->inventory_transaction_id !== $transaction->id) {
            throw new InventoryDomainException("Line does not belong to this transaction.");
        }

        if ($dto->quantity <= 0) {
            throw new InventoryDomainException("Quantity must be greater than zero.");
        }

        return $this->repository->updateLine($line, $dto->toArray());
    }
}
