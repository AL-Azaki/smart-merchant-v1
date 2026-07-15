<?php

namespace App\Domains\Core\DTOs;

class SubscriptionSearchCriteriaDTO
{
    public function __construct(
        public readonly string $accountId,
        public readonly ?string $keyword = null,
        public readonly ?string $status = null,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'created_at',
        public readonly string $sortDir = 'desc'
    ) {}

    public static function fromRequest(array $data, string $accountId): self
    {
        return new self(
            accountId: $accountId,
            keyword: $data['keyword'] ?? null,
            status: $data['status'] ?? null,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'created_at',
            sortDir: strtolower($data['sort_dir'] ?? 'desc') === 'asc' ? 'asc' : 'desc'
        );
    }
}
