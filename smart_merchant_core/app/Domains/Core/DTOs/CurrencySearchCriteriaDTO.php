<?php

namespace App\Domains\Core\DTOs;

class CurrencySearchCriteriaDTO
{
    public function __construct(
        public readonly ?string $keyword = null,
        public readonly ?bool $isActive = null,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'code',
        public readonly string $sortDir = 'asc'
    ) {}

    public static function fromRequest(array $data): self
    {
        $isActive = null;
        if (isset($data['is_active'])) {
            $isActive = filter_var($data['is_active'], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
        }

        return new self(
            keyword: $data['keyword'] ?? null,
            isActive: $isActive,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'code',
            sortDir: strtolower($data['sort_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc'
        );
    }
}
