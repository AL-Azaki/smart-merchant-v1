<?php

namespace App\Domains\Inventory\Repositories\Eloquent;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class InventoryTransactionEloquentRepository implements InventoryTransactionRepositoryInterface
{
    public function create(array $data): InventoryTransaction
    {
        return DB::transaction(function () use ($data) {
            $lines = $data['lines'] ?? [];
            unset($data['lines']);

            $transaction = InventoryTransaction::create($data);

            if (!empty($lines)) {
                $transaction->lines()->createMany($lines);
            }

            return $transaction->load('lines');
        });
    }

    public function update(InventoryTransaction $transaction, array $data): InventoryTransaction
    {
        return DB::transaction(function () use ($transaction, $data) {
            $lines = $data['lines'] ?? null;
            unset($data['lines']);

            $transaction->update($data);

            if ($lines !== null) {
                $transaction->lines()->delete();
                $transaction->lines()->createMany($lines);
            }

            return $transaction->load('lines');
        });
    }

    public function delete(InventoryTransaction $transaction): bool
    {
        return DB::transaction(function () use ($transaction) {
            $transaction->lines()->delete();
            return $transaction->delete();
        });
    }

    public function findById(string $businessId, string $id): ?InventoryTransaction
    {
        return InventoryTransaction::where('business_id', $businessId)
            ->where('id', $id)
            ->with('lines')
            ->first();
    }

    public function getAll(string $businessId): Collection
    {
        return InventoryTransaction::where('business_id', $businessId)
            ->with('lines')
            ->get();
    }

    public function exists(string $businessId, string $id): bool
    {
        return InventoryTransaction::where('business_id', $businessId)
            ->where('id', $id)
            ->exists();
    }
}
