<?php

namespace App\Domains\Catalog\DTOs;

class CreateProductDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $productCode,
        public readonly string $productName,
        public readonly ?string $categoryId = null,
        public readonly ?string $brandId = null,
        public readonly ?string $taxId = null,
        public readonly string $productType = 'standard',
        public readonly ?string $description = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            productCode: $data['product_code'],
            productName: $data['product_name'],
            categoryId: $data['category_id'] ?? null,
            brandId: $data['brand_id'] ?? null,
            taxId: $data['tax_id'] ?? null,
            productType: $data['product_type'] ?? 'standard',
            description: $data['description'] ?? null
        );
    }
    
    public function toArray(): array
    {
        return [
            'business_id' => $this->businessId,
            'product_code' => $this->productCode,
            'product_name' => $this->productName,
            'category_id' => $this->categoryId,
            'brand_id' => $this->brandId,
            'tax_id' => $this->taxId,
            'product_type' => $this->productType,
            'description' => $this->description,
        ];
    }
}
