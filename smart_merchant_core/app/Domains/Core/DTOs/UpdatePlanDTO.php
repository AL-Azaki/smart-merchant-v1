<?php

namespace App\Domains\Core\DTOs;

class UpdatePlanDTO
{
    public function __construct(
        public readonly ?string $name = null,
        public readonly ?string $description = null,
        public readonly ?float $monthlyPrice = null,
        public readonly ?float $annualPrice = null,
        public readonly ?int $maxBusinesses = null,
        public readonly ?int $maxUsers = null,
        public readonly ?array $features = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            name: $data['name'] ?? null,
            description: $data['description'] ?? null,
            monthlyPrice: isset($data['monthly_price']) ? (float) $data['monthly_price'] : null,
            annualPrice: isset($data['annual_price']) ? (float) $data['annual_price'] : null,
            maxBusinesses: isset($data['max_businesses']) ? (int) $data['max_businesses'] : null,
            maxUsers: isset($data['max_users']) ? (int) $data['max_users'] : null,
            features: $data['features'] ?? null
        );
    }

    public function toArray(): array
    {
        $data = [
            'name'           => $this->name,
            'description'    => $this->description,
            'monthly_price'  => $this->monthlyPrice,
            'annual_price'   => $this->annualPrice,
            'max_businesses' => $this->maxBusinesses,
            'max_users'      => $this->maxUsers,
            'features'       => $this->features !== null ? json_encode($this->features) : null,
        ];
        return array_filter($data, fn($value) => $value !== null);
    }
}
