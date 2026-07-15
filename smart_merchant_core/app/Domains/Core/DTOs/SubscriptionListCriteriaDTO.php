<?php

namespace App\Domains\Core\DTOs;

class SubscriptionListCriteriaDTO
{
    public function __construct(
        public readonly string $accountId,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'created_at',
        public readonly string $sortDir = 'desc'
    ) {}

    public static function fromRequest(array $data, string $accountId): self
    {
        return new self(
            accountId: $accountId,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'created_at',
            sortDir: strtolower($data['sort_dir'] ?? 'desc') === 'asc' ? 'asc' : 'desc'
        );
    }
}
