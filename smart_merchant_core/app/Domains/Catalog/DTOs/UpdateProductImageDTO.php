<?php

namespace App\Domains\Catalog\DTOs;

class UpdateProductImageDTO
{
    public function __construct(
        public readonly ?bool $isPrimary = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            isPrimary: isset($data['is_primary']) ? filter_var($data['is_primary'], FILTER_VALIDATE_BOOLEAN) : null
        );
    }

    public function toArray(): array
    {
        $data = [];
        if ($this->isPrimary !== null) $data['is_primary'] = $this->isPrimary;
        return $data;
    }
}
