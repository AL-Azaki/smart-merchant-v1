<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\DTOs\InventoryTransaction\TransactionLineDTO;
use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Models\InventoryTransactionLine;
use App\Domains\Catalog\Models\ProductUnit;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Exceptions\InventoryDomainException;

class AddTransactionLineAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(InventoryTransaction $transaction, TransactionLineDTO $dto): InventoryTransactionLine
    {
        if ($transaction->status !== 'Draft') {
            throw new InventoryDomainException("Lines can only be added to Draft transactions.");
        }

        $unit = ProductUnit::find($dto->productUnitId);
        if (!$unit || $unit->business_id !== $transaction->business_id) {
            throw new InventoryDomainException("Product unit does not exist or does not belong to this business.");
        }

        if ($dto->quantity <= 0) {
            throw new InventoryDomainException("Quantity must be greater than zero.");
        }

        return $this->repository->addLine($transaction, $dto->toArray());
    }
}
