<?php

namespace App\Domains\Core\DTOs;

class CreateRoleDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $name,
        public readonly ?string $description = null,
        public readonly bool $isSystem = false
    ) {}

    public static function fromRequest(array $data, string $businessId): self
    {
        return new self(
            businessId: $businessId,
            name: $data['name'],
            description: $data['description'] ?? null,
            isSystem: false // Tenants cannot create system roles via API
        );
    }
}
