<?php

namespace App\Domains\Core\DTOs;

class CreatePlanDTO
{
    public function __construct(
        public readonly string $name,
        public readonly ?string $description = null,
        public readonly float $monthlyPrice = 0.0,
        public readonly float $annualPrice = 0.0,
        public readonly int $maxBusinesses = 1,
        public readonly int $maxUsers = 1,
        public readonly ?array $features = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            name: $data['name'],
            description: $data['description'] ?? null,
            monthlyPrice: (float) ($data['monthly_price'] ?? 0.0),
            annualPrice: (float) ($data['annual_price'] ?? 0.0),
            maxBusinesses: (int) ($data['max_businesses'] ?? 1),
            maxUsers: (int) ($data['max_users'] ?? 1),
            features: $data['features'] ?? null
        );
    }
}
