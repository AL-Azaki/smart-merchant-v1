<?php

namespace App\Domains\Catalog\DTOs;

class BranchProductPriceListCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $branchId,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'created_at',
        public readonly string $sortDir = 'desc'
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            branchId: $data['branch_id'],
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'created_at',
            sortDir: strtolower($data['sort_dir'] ?? 'desc') === 'desc' ? 'desc' : 'asc'
        );
    }
}
