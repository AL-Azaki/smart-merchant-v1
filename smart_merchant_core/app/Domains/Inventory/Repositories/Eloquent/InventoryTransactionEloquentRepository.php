<?php

namespace App\Domains\Inventory\Repositories\Eloquent;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Models\InventoryTransactionLine;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\DTOs\InventoryTransaction\TransactionCriteriaDTO;
use App\Domains\Inventory\DTOs\InventoryTransaction\UpdateTransactionDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class InventoryTransactionEloquentRepository implements InventoryTransactionRepositoryInterface
{
    public function create(array $data): InventoryTransaction
    {
        return InventoryTransaction::create($data);
    }

    public function findById(string $id, array $with = []): ?InventoryTransaction
    {
        return InventoryTransaction::with($with)->find($id);
    }

    public function search(TransactionCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = InventoryTransaction::with(['warehouse', 'creator', 'lines.productUnit'])
            ->where('business_id', $criteria->businessId);

        if ($criteria->warehouseId !== null) {
            $query->where('warehouse_id', $criteria->warehouseId);
        }

        if ($criteria->status !== null) {
            $query->where('status', $criteria->status);
        }

        if ($criteria->transactionType !== null) {
            $query->where('transaction_type', $criteria->transactionType);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                      ->paginate($criteria->perPage);
    }

    public function update(InventoryTransaction $transaction, UpdateTransactionDTO $dto): InventoryTransaction
    {
        $transaction->update($dto->toArray());
        return $transaction;
    }

    public function delete(InventoryTransaction $transaction): bool
    {
        return (bool) $transaction->delete();
    }

    public function addLine(InventoryTransaction $transaction, array $data): InventoryTransactionLine
    {
        $maxLine = $transaction->lines()->max('line_number') ?? 0;
        $data['line_number'] = $maxLine + 1;
        $data['inventory_transaction_id'] = $transaction->id;
        $data['business_id'] = $transaction->business_id;

        return InventoryTransactionLine::create($data);
    }

    public function updateLine(InventoryTransactionLine $line, array $data): InventoryTransactionLine
    {
        $line->update($data);
        return $line;
    }

    public function removeLine(InventoryTransactionLine $line): bool
    {
        return (bool) $line->delete();
    }

    public function findLineById(string $id): ?InventoryTransactionLine
    {
        return InventoryTransactionLine::find($id);
    }

    public function changeStatus(InventoryTransaction $transaction, string $status, ?string $userId = null): InventoryTransaction
    {
        $updateData = ['status' => $status];

        if ($status === 'Posted') {
            $updateData['posted_by'] = $userId;
            $updateData['posted_at'] = now();
        } elseif ($status === 'Reversed') {
            $updateData['reversed_by'] = $userId;
            $updateData['reversed_at'] = now();
        }

        $transaction->update($updateData);
        return $transaction;
    }
}
