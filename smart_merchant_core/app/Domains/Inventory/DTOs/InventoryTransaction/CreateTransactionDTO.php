<?php

namespace App\Domains\Inventory\DTOs\InventoryTransaction;

class CreateTransactionDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $branchId,
        public readonly string $warehouseId,
        public readonly string $transactionType,
        public readonly string $movementDirection,
        public readonly ?string $referenceType = null,
        public readonly ?string $referenceId = null,
        public readonly ?string $transactionDate = null,
        public readonly ?string $createdBy = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            branchId: $data['branch_id'],
            warehouseId: $data['warehouse_id'],
            transactionType: $data['transaction_type'],
            movementDirection: $data['movement_direction'],
            referenceType: $data['reference_type'] ?? null,
            referenceId: $data['reference_id'] ?? null,
            transactionDate: $data['transaction_date'] ?? null,
            createdBy: $data['created_by'] ?? null
        );
    }

    public function toArray(): array
    {
        return [
            'business_id' => $this->businessId,
            'branch_id' => $this->branchId,
            'warehouse_id' => $this->warehouseId,
            'transaction_type' => $this->transactionType,
            'movement_direction' => $this->movementDirection,
            'status' => 'Draft',
            'reference_type' => $this->referenceType,
            'reference_id' => $this->referenceId,
            'transaction_date' => $this->transactionDate ?? now(),
            'created_by' => $this->createdBy,
        ];
    }
}
