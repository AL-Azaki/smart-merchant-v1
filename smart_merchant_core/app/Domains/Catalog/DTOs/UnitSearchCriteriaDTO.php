<?php

namespace App\Domains\Catalog\DTOs;

class UnitSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $keyword = null,
        public readonly ?bool $isActive = null,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'unit_name',
        public readonly string $sortDir = 'asc'
    ) {}

    public static function fromRequest(array $data): self
    {
        $isActive = null;
        if (isset($data['is_active'])) {
            $isActive = filter_var($data['is_active'], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
        }

        return new self(
            businessId: $data['business_id'],
            keyword: $data['keyword'] ?? null,
            isActive: $isActive,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'unit_name',
            sortDir: strtolower($data['sort_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc'
        );
    }
}


