<?php

namespace App\Domains\Catalog\DTOs;

class CreateUnitDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $unitName,
        public readonly string $unitSymbol,
        public readonly ?string $unitDescription = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            unitName: $data['unit_name'],
            unitSymbol: $data['unit_symbol'],
            unitDescription: $data['unit_description'] ?? null
        );
    }
    
    public function toArray(): array
    {
        return [
            'business_id' => $this->businessId,
            'unit_name' => $this->unitName,
            'unit_symbol' => $this->unitSymbol,
            'unit_description' => $this->unitDescription,
        ];
    }
}


