<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class GetTransactionAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(string $id, string $businessId): InventoryTransaction
    {
        $transaction = $this->repository->findById($id, ['warehouse', 'creator', 'lines.productUnit']);

        if (!$transaction || $transaction->business_id !== $businessId) {
            throw new ModelNotFoundException("Transaction not found.");
        }

        return $transaction;
    }
}
