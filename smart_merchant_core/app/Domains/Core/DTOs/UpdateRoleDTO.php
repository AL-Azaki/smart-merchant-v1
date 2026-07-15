<?php

namespace App\Domains\Core\DTOs;

class UpdateRoleDTO
{
    public function __construct(
        public readonly ?string $name = null,
        public readonly ?string $description = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            name: $data['name'] ?? null,
            description: $data['description'] ?? null
        );
    }

    public function toArray(): array
    {
        $data = [
            'name'        => $this->name,
            'description' => $this->description,
        ];
        return array_filter($data, fn($value) => $value !== null);
    }
}
