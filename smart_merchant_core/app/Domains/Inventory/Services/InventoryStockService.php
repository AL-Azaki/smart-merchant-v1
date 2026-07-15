<?php

namespace App\Domains\Inventory\Services;

use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use Exception;

class InventoryStockService
{
    public function __construct(
        private InventoryTransactionRepositoryInterface $repository
    ) {}

    public function increaseStock(
        string $businessId,
        string $warehouseId,
        string $productUnitId,
        float $quantity,
        float $unitCost,
        string $referenceType,
        string $referenceId,
        string $notes = ''
    ): InventoryTransaction {
        if ($quantity <= 0) {
            throw new Exception("Quantity must be strictly positive.");
        }

        $data = [
            'business_id' => $businessId,
            'warehouse_id' => $warehouseId,
            'transaction_type' => 'Receipt',
            'status' => 'Posted',
            'reference_type' => $referenceType,
            'reference_id' => $referenceId,
            'notes' => $notes,
            'lines' => [
                [
                    'business_id' => $businessId,
                    'product_unit_id' => $productUnitId,
                    'line_number' => 1,
                    'quantity' => $quantity,
                    'unit_cost' => $unitCost,
                ]
            ]
        ];

        return $this->repository->create($data);
    }

    public function decreaseStock(
        string $businessId,
        string $warehouseId,
        string $productUnitId,
        float $quantity,
        string $referenceType,
        string $referenceId,
        string $notes = ''
    ): InventoryTransaction {
        if ($quantity <= 0) {
            throw new Exception("Quantity must be strictly positive.");
        }

        $currentStock = $this->getCurrentStock($businessId, $warehouseId, $productUnitId);
        
        if ($currentStock < $quantity) {
            throw new Exception("Insufficient stock to perform this dispatch.");
        }

        $data = [
            'business_id' => $businessId,
            'warehouse_id' => $warehouseId,
            'transaction_type' => 'Dispatch',
            'status' => 'Posted',
            'reference_type' => $referenceType,
            'reference_id' => $referenceId,
            'notes' => $notes,
            'lines' => [
                [
                    'business_id' => $businessId,
                    'product_unit_id' => $productUnitId,
                    'line_number' => 1,
                    'quantity' => $quantity,
                    'unit_cost' => 0, // Cost is evaluated via average cost engine in future
                ]
            ]
        ];

        return $this->repository->create($data);
    }

    public function decreaseStockBulk(
        string $businessId,
        string $warehouseId,
        array $linesData,
        string $referenceType,
        string $referenceId,
        string $notes = ''
    ): InventoryTransaction {
        $lines = [];
        foreach ($linesData as $lineData) {
            $currentStock = $this->getCurrentStock($businessId, $warehouseId, $lineData['product_unit_id']);
            if ($currentStock < $lineData['quantity']) {
                throw new Exception("Insufficient stock to perform this dispatch.");
            }
            $lines[] = [
                'business_id' => $businessId,
                'product_unit_id' => $lineData['product_unit_id'],
                'line_number' => $lineData['line_number'],
                'quantity' => $lineData['quantity'],
                'unit_cost' => $lineData['unit_cost'],
            ];
        }

        $data = [
            'business_id' => $businessId,
            'warehouse_id' => $warehouseId,
            'transaction_type' => 'Dispatch',
            'status' => 'Posted',
            'reference_type' => $referenceType,
            'reference_id' => $referenceId,
            'notes' => $notes,
            'lines' => $lines
        ];

        return $this->repository->create($data);
    }

    public function reverseStockMovement(
        InventoryTransaction $transaction,
        string $notes = ''
    ): InventoryTransaction {
        if ($transaction->status !== 'Posted') {
            throw new Exception("Only Posted transactions can be reversed.");
        }

        $reverseType = match ($transaction->transaction_type) {
            'Receipt' => 'Dispatch',
            'Dispatch' => 'Receipt',
            'Adjustment In' => 'Adjustment Out',
            'Adjustment Out' => 'Adjustment In',
            default => throw new Exception("Unknown transaction type for reversal.")
        };

        $lines = [];
        foreach ($transaction->lines as $line) {
            $lines[] = [
                'business_id' => $line->business_id,
                'product_unit_id' => $line->product_unit_id,
                'line_number' => $line->line_number,
                'quantity' => $line->quantity,
                'unit_cost' => $line->unit_cost,
            ];
        }

        $data = [
            'business_id' => $transaction->business_id,
            'warehouse_id' => $transaction->warehouse_id,
            'transaction_type' => $reverseType,
            'status' => 'Posted',
            'reference_type' => $transaction->reference_type,
            'reference_id' => $transaction->reference_id,
            'notes' => 'Reversal of ' . $transaction->id . '. ' . $notes,
            'lines' => $lines
        ];

        $reversal = $this->repository->create($data);

        $this->repository->update($transaction, ['status' => 'Reversed']);

        return $reversal;
    }

    public function getCurrentStock(string $businessId, string $warehouseId, string $productUnitId): float
    {
        $transactions = $this->repository->getAll($businessId);

        $stock = 0.0;

        foreach ($transactions as $transaction) {
            if ($transaction->status === 'Draft') {
                continue;
            }

            if ((string)$transaction->warehouse_id !== $warehouseId) {
                continue;
            }

            foreach ($transaction->lines as $line) {
                if ((string)$line->product_unit_id === $productUnitId) {
                    if (in_array($transaction->transaction_type, ['Receipt', 'Adjustment In'])) {
                        $stock += (float)$line->quantity;
                    } elseif (in_array($transaction->transaction_type, ['Dispatch', 'Adjustment Out'])) {
                        $stock -= (float)$line->quantity;
                    }
                }
            }
        }

        return $stock;
    }

    public function hasTransactionForReference(string $businessId, string $referenceType, string $referenceId): bool
    {
        $transactions = $this->repository->getAll($businessId);
        foreach ($transactions as $tx) {
            if ($tx->reference_type === $referenceType && $tx->reference_id === $referenceId && $tx->status !== 'Reversed') {
                return true;
            }
        }
        return false;
    }
}
