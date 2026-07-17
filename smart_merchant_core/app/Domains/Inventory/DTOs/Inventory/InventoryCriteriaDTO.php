<?php

namespace App\Domains\Inventory\DTOs\Inventory;

class InventoryCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $warehouseId = null,
        public readonly ?string $productUnitId = null,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'created_at',
        public readonly string $sortDir = 'desc'
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            warehouseId: $data['warehouse_id'] ?? null,
            productUnitId: $data['product_unit_id'] ?? null,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'created_at',
            sortDir: strtolower($data['sort_dir'] ?? 'desc') === 'desc' ? 'desc' : 'asc'
        );
    }
}
