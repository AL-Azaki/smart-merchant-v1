<?php

namespace App\Domains\Catalog\DTOs;

class CreateProductImageDTO
{
    public function __construct(
        public readonly string $productId,
        public readonly string $imagePath,
        public readonly bool $isPrimary = false
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            productId: $data['product_id'],
            imagePath: $data['image_path'],
            isPrimary: filter_var($data['is_primary'] ?? false, FILTER_VALIDATE_BOOLEAN)
        );
    }
    
    public function toArray(): array
    {
        return [
            'product_id' => $this->productId,
            'image_path' => $this->imagePath,
            'is_primary' => $this->isPrimary,
        ];
    }
}
