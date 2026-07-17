<?php

namespace App\Domains\Catalog\DTOs;

class UpdateProductDTO
{
    public function __construct(
        public readonly ?string $productCode = null,
        public readonly ?string $productName = null,
        public readonly ?string $categoryId = null,
        public readonly ?string $brandId = null,
        public readonly ?string $taxId = null,
        public readonly ?string $productType = null,
        public readonly ?string $description = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            productCode: $data['product_code'] ?? null,
            productName: $data['product_name'] ?? null,
            categoryId: array_key_exists('category_id', $data) ? $data['category_id'] : null,
            brandId: array_key_exists('brand_id', $data) ? $data['brand_id'] : null,
            taxId: array_key_exists('tax_id', $data) ? $data['tax_id'] : null,
            productType: $data['product_type'] ?? null,
            description: array_key_exists('description', $data) ? $data['description'] : null
        );
    }

    public function toArray(): array
    {
        $data = [];
        if ($this->productCode !== null) $data['product_code'] = $this->productCode;
        if ($this->productName !== null) $data['product_name'] = $this->productName;
        if ($this->categoryId !== null) $data['category_id'] = $this->categoryId;
        if ($this->brandId !== null) $data['brand_id'] = $this->brandId;
        if ($this->taxId !== null) $data['tax_id'] = $this->taxId;
        if ($this->productType !== null) $data['product_type'] = $this->productType;
        if ($this->description !== null) $data['description'] = $this->description;
        return $data;
    }
}
