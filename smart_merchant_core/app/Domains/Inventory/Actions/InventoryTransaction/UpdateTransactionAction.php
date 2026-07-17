<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\DTOs\InventoryTransaction\UpdateTransactionDTO;
use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class UpdateTransactionAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(InventoryTransaction $transaction, UpdateTransactionDTO $dto): InventoryTransaction
    {
        if ($transaction->status !== 'Draft') {
            throw new InventoryDomainException("Only Draft transactions can be updated.");
        }

        return $this->repository->update($transaction, $dto);
    }
}
