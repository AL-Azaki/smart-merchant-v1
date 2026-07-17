<?php

namespace App\Domains\Inventory\DTOs\InventoryTransaction;

class TransactionCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $warehouseId = null,
        public readonly ?string $status = null,
        public readonly ?string $transactionType = null,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'created_at',
        public readonly string $sortDir = 'desc'
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            warehouseId: $data['warehouse_id'] ?? null,
            status: $data['status'] ?? null,
            transactionType: $data['transaction_type'] ?? null,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'created_at',
            sortDir: strtolower($data['sort_dir'] ?? 'desc') === 'desc' ? 'desc' : 'asc'
        );
    }
}
