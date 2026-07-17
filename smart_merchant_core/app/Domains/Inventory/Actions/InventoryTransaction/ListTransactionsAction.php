<?php

namespace App\Domains\Inventory\Actions\InventoryTransaction;

use App\Domains\Inventory\DTOs\InventoryTransaction\TransactionCriteriaDTO;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ListTransactionsAction
{
    public function __construct(private readonly InventoryTransactionRepositoryInterface $repository) {}

    public function handle(TransactionCriteriaDTO $criteria): LengthAwarePaginator
    {
        return $this->repository->search($criteria);
    }
}
