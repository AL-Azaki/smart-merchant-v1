<?php

namespace App\Domains\Catalog\DTOs;

class UnitListCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'unit_name',
        public readonly string $sortDir = 'asc'
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'unit_name',
            sortDir: strtolower($data['sort_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc'
        );
    }
}


