<?php

namespace App\Domains\Core\DTOs;

class PermissionSearchCriteriaDTO
{
    public function __construct(
        public readonly ?string $keyword = null,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'group_name',
        public readonly string $sortDir = 'asc'
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            keyword: $data['keyword'] ?? null,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'group_name',
            sortDir: strtolower($data['sort_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc'
        );
    }
}
