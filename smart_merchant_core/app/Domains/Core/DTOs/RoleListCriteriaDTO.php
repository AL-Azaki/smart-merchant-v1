<?php

namespace App\Domains\Core\DTOs;

class RoleListCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'created_at',
        public readonly string $sortDir = 'desc'
    ) {}

    public static function fromRequest(array $data, string $businessId): self
    {
        return new self(
            businessId: $businessId,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'created_at',
            sortDir: strtolower($data['sort_dir'] ?? 'desc') === 'asc' ? 'asc' : 'desc'
        );
    }
}
