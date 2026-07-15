<?php

namespace App\Domains\Core\DTOs;

class BranchSearchCriteriaDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly ?string $keyword = null,
        public readonly ?bool $isActive = null,
        public readonly ?bool $isDefault = null,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'created_at',
        public readonly string $sortDir = 'desc',
        public readonly array $includes = []
    ) {}

    public static function fromRequest(array $data, string $businessId): self
    {
        $includes = isset($data['include']) ? array_filter(array_map('trim', explode(',', $data['include']))) : [];
        
        return new self(
            businessId: $businessId,
            keyword: $data['keyword'] ?? null,
            isActive: isset($data['is_active']) ? filter_var($data['is_active'], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) : null,
            isDefault: isset($data['is_default']) ? filter_var($data['is_default'], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) : null,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'created_at',
            sortDir: strtolower($data['sort_dir'] ?? 'desc') === 'asc' ? 'asc' : 'desc',
            includes: $includes
        );
    }
}
