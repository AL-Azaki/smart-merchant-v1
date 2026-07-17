<?php

namespace App\Domains\Catalog\DTOs;

class UpdateBranchProductPriceDTO
{
    public function __construct(
        public readonly ?float $purchasePrice = null,
        public readonly ?float $sellingPrice = null,
        public readonly ?float $minimumPrice = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            purchasePrice: isset($data['purchase_price']) ? (float)$data['purchase_price'] : null,
            sellingPrice: isset($data['selling_price']) ? (float)$data['selling_price'] : null,
            minimumPrice: isset($data['minimum_price']) ? (float)$data['minimum_price'] : null
        );
    }

    public function toArray(): array
    {
        $data = [];
        if ($this->purchasePrice !== null) $data['purchase_price'] = $this->purchasePrice;
        if ($this->sellingPrice !== null) $data['selling_price'] = $this->sellingPrice;
        if ($this->minimumPrice !== null) $data['minimum_price'] = $this->minimumPrice;
        return $data;
    }
}
