<?php

namespace App\Domains\Catalog\DTOs;

class UpdateUnitDTO
{
    public function __construct(
        public readonly ?string $unitName = null,
        public readonly ?string $unitSymbol = null,
        public readonly ?string $unitDescription = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            unitName: $data['unit_name'] ?? null,
            unitSymbol: $data['unit_symbol'] ?? null,
            unitDescription: $data['unit_description'] ?? null
        );
    }

    public function toArray(): array
    {
        $data = [
            'unit_name'          => $this->unitName,
            'unit_symbol'        => $this->unitSymbol,
            'unit_description'   => $this->unitDescription,
        ];
        return array_filter($data, fn($value) => $value !== null);
    }
}

