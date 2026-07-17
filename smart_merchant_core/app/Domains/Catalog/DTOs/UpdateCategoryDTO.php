<?php

namespace App\Domains\Catalog\DTOs;

class UpdateCategoryDTO
{
    public function __construct(
        public readonly ?string $categoryName = null,
        public readonly ?string $categoryCode = null,
        public readonly ?string $parentId = null,
        public readonly ?string $description = null,
        public readonly ?string $imagePath = null,
        public readonly ?int $sortOrder = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            categoryName: $data['category_name'] ?? null,
            categoryCode: $data['category_code'] ?? null,
            parentId: array_key_exists('parent_id', $data) ? $data['parent_id'] : null,
            description: array_key_exists('description', $data) ? $data['description'] : null,
            imagePath: array_key_exists('image_path', $data) ? $data['image_path'] : null,
            sortOrder: isset($data['sort_order']) ? (int) $data['sort_order'] : null
        );
    }

    public function toArray(): array
    {
        $data = [];
        if ($this->categoryName !== null) $data['category_name'] = $this->categoryName;
        if ($this->categoryCode !== null) $data['category_code'] = $this->categoryCode;
        if ($this->parentId !== null) $data['parent_id'] = $this->parentId;
        if ($this->description !== null) $data['description'] = $this->description;
        if ($this->imagePath !== null) $data['image_path'] = $this->imagePath;
        if ($this->sortOrder !== null) $data['sort_order'] = $this->sortOrder;
        return $data;
    }
}

