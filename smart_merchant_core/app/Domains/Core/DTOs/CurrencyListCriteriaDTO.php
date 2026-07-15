<?php

namespace App\Domains\Core\DTOs;

class CurrencyListCriteriaDTO
{
    public function __construct(
        public readonly int $perPage = 15,
        public readonly string $sortField = 'code',
        public readonly string $sortDir = 'asc'
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'code',
            sortDir: strtolower($data['sort_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc'
        );
    }
}
