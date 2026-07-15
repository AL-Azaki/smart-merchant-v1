<?php

namespace App\Domains\Inventory\Repositories\Contracts;

use App\Domains\Inventory\Models\InventoryTransaction;
use Illuminate\Support\Collection;

interface InventoryTransactionRepositoryInterface
{
    public function create(array $data): InventoryTransaction;
    public function update(InventoryTransaction $transaction, array $data): InventoryTransaction;
    public function delete(InventoryTransaction $transaction): bool;
    public function findById(string $businessId, string $id): ?InventoryTransaction;
    public function getAll(string $businessId): Collection;
    public function exists(string $businessId, string $id): bool;
}
