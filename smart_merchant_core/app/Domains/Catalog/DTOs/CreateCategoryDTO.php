<?php

namespace App\Domains\Catalog\DTOs;

class CreateCategoryDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $categoryName,
        public readonly ?string $categoryCode = null,
        public readonly ?string $parentId = null,
        public readonly ?string $description = null,
        public readonly ?string $imagePath = null,
        public readonly int $sortOrder = 0
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            categoryName: $data['category_name'],
            categoryCode: $data['category_code'] ?? null,
            parentId: $data['parent_id'] ?? null,
            description: $data['description'] ?? null,
            imagePath: $data['image_path'] ?? null,
            sortOrder: (int) ($data['sort_order'] ?? 0)
        );
    }
    
    public function toArray(): array
    {
        return [
            'business_id' => $this->businessId,
            'category_name' => $this->categoryName,
            'category_code' => $this->categoryCode,
            'parent_id' => $this->parentId,
            'description' => $this->description,
            'image_path' => $this->imagePath,
            'sort_order' => $this->sortOrder,
        ];
    }
}

