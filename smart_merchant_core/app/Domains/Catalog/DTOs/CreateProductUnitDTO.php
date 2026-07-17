<?php

namespace App\Domains\Catalog\DTOs;

class CreateProductUnitDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $productId,
        public readonly string $unitId,
        public readonly ?string $sku = null,
        public readonly ?string $barcode = null,
        public readonly float $conversionFactor = 1.0000,
        public readonly float $purchasePrice = 0.00,
        public readonly float $sellingPrice = 0.00,
        public readonly float $minimumPrice = 0.00,
        public readonly bool $isBaseUnit = false
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            productId: $data['product_id'],
            unitId: $data['unit_id'],
            sku: $data['sku'] ?? null,
            barcode: $data['barcode'] ?? null,
            conversionFactor: isset($data['conversion_factor']) ? (float)$data['conversion_factor'] : 1.0000,
            purchasePrice: isset($data['purchase_price']) ? (float)$data['purchase_price'] : 0.00,
            sellingPrice: isset($data['selling_price']) ? (float)$data['selling_price'] : 0.00,
            minimumPrice: isset($data['minimum_price']) ? (float)$data['minimum_price'] : 0.00,
            isBaseUnit: filter_var($data['is_base_unit'] ?? false, FILTER_VALIDATE_BOOLEAN)
        );
    }
    
    public function toArray(): array
    {
        return [
            'business_id' => $this->businessId,
            'product_id' => $this->productId,
            'unit_id' => $this->unitId,
            'sku' => $this->sku,
            'barcode' => $this->barcode,
            'conversion_factor' => $this->conversionFactor,
            'purchase_price' => $this->purchasePrice,
            'selling_price' => $this->sellingPrice,
            'minimum_price' => $this->minimumPrice,
            'is_base_unit' => $this->isBaseUnit,
        ];
    }
}
