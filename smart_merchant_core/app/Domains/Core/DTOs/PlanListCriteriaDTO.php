<?php

namespace App\Domains\Core\DTOs;

class PlanListCriteriaDTO
{
    public function __construct(
        public readonly int $perPage = 15,
        public readonly string $sortField = 'monthly_price',
        public readonly string $sortDir = 'asc'
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'monthly_price',
            sortDir: strtolower($data['sort_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc'
        );
    }
}
