<?php

namespace App\Domains\Inventory\Repositories\Contracts;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Models\InventoryTransactionLine;
use App\Domains\Inventory\DTOs\InventoryTransaction\TransactionCriteriaDTO;
use App\Domains\Inventory\DTOs\InventoryTransaction\UpdateTransactionDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface InventoryTransactionRepositoryInterface
{
    public function create(array $data): InventoryTransaction;

    public function findById(string $id, array $with = []): ?InventoryTransaction;

    public function search(TransactionCriteriaDTO $criteria): LengthAwarePaginator;

    public function update(InventoryTransaction $transaction, UpdateTransactionDTO $dto): InventoryTransaction;

    public function delete(InventoryTransaction $transaction): bool;

    public function addLine(InventoryTransaction $transaction, array $data): InventoryTransactionLine;

    public function updateLine(InventoryTransactionLine $line, array $data): InventoryTransactionLine;

    public function removeLine(InventoryTransactionLine $line): bool;

    public function findLineById(string $id): ?InventoryTransactionLine;

    public function changeStatus(InventoryTransaction $transaction, string $status, ?string $userId = null): InventoryTransaction;
}
