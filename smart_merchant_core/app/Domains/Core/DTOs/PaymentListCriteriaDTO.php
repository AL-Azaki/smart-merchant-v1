<?php

namespace App\Domains\Core\DTOs;

class PaymentListCriteriaDTO
{
    public function __construct(
        public readonly string $subscriptionId,
        public readonly int $perPage = 15,
        public readonly string $sortField = 'created_at',
        public readonly string $sortDir = 'desc'
    ) {}

    public static function fromRequest(array $data, string $subscriptionId): self
    {
        return new self(
            subscriptionId: $subscriptionId,
            perPage: (int) ($data['per_page'] ?? 15),
            sortField: $data['sort_by'] ?? 'created_at',
            sortDir: strtolower($data['sort_dir'] ?? 'desc') === 'asc' ? 'asc' : 'desc'
        );
    }
}
