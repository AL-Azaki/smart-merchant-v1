<?php

namespace App\Domains\Catalog\DTOs;

class CreateBranchProductPriceDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $branchId,
        public readonly string $productUnitId,
        public readonly float $purchasePrice = 0.00,
        public readonly float $sellingPrice = 0.00,
        public readonly float $minimumPrice = 0.00
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            branchId: $data['branch_id'],
            productUnitId: $data['product_unit_id'],
            purchasePrice: isset($data['purchase_price']) ? (float)$data['purchase_price'] : 0.00,
            sellingPrice: isset($data['selling_price']) ? (float)$data['selling_price'] : 0.00,
            minimumPrice: isset($data['minimum_price']) ? (float)$data['minimum_price'] : 0.00
        );
    }
    
    public function toArray(): array
    {
        return [
            'business_id' => $this->businessId,
            'branch_id' => $this->branchId,
            'product_unit_id' => $this->productUnitId,
            'purchase_price' => $this->purchasePrice,
            'selling_price' => $this->sellingPrice,
            'minimum_price' => $this->minimumPrice,
        ];
    }
}
