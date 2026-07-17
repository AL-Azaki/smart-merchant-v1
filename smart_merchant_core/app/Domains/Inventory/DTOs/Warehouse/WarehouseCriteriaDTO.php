<?php

namespace App\Domains\Inventory\DTOs\Warehouse;

class WarehouseCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $branchId = null,
        public readonly ?string $keyword = null,
        public readonly ?bool $isActive = null,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'created_at',
        public readonly string $sortDir = 'desc'
    ) {}

    public static function fromRequest(array $data): self
    {
        $isActive = null;
        if (isset($data['is_active'])) {
            $isActive = filter_var($data['is_active'], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
        }

        return new self(
            businessId: $data['business_id'],
            branchId: $data['branch_id'] ?? null,
            keyword: $data['keyword'] ?? null,
            isActive: $isActive,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'created_at',
            sortDir: strtolower($data['sort_dir'] ?? 'desc') === 'desc' ? 'desc' : 'asc'
        );
    }
}
