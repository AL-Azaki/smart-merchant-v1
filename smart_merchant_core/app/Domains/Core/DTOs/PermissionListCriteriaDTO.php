<?php

namespace App\Domains\Core\DTOs;

class PermissionListCriteriaDTO
{
    public function __construct(
        public readonly int $perPage = 15,
        public readonly string $sortField = 'group_name',
        public readonly string $sortDir = 'asc'
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'group_name',
            sortDir: strtolower($data['sort_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc'
        );
    }
}
