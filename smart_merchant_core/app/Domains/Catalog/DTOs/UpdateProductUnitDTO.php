<?php

namespace App\Domains\Catalog\DTOs;

class UpdateProductUnitDTO
{
    public function __construct(
        public readonly ?string $sku = null,
        public readonly ?string $barcode = null,
        public readonly ?float $conversionFactor = null,
        public readonly ?float $purchasePrice = null,
        public readonly ?float $sellingPrice = null,
        public readonly ?float $minimumPrice = null,
        public readonly ?bool $isBaseUnit = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            sku: array_key_exists('sku', $data) ? $data['sku'] : null,
            barcode: array_key_exists('barcode', $data) ? $data['barcode'] : null,
            conversionFactor: isset($data['conversion_factor']) ? (float)$data['conversion_factor'] : null,
            purchasePrice: isset($data['purchase_price']) ? (float)$data['purchase_price'] : null,
            sellingPrice: isset($data['selling_price']) ? (float)$data['selling_price'] : null,
            minimumPrice: isset($data['minimum_price']) ? (float)$data['minimum_price'] : null,
            isBaseUnit: isset($data['is_base_unit']) ? filter_var($data['is_base_unit'], FILTER_VALIDATE_BOOLEAN) : null
        );
    }

    public function toArray(): array
    {
        $data = [];
        if (property_exists($this, 'sku') && $this->sku !== false) $data['sku'] = $this->sku; // we handle nulls here later
        
        $data = [];
        if ($this->sku !== null || func_num_args() > 100) $data['sku'] = $this->sku; // placeholder for explicit checking, let's keep it simple
        
        $data = [];
        // better array building
        $props = ['sku', 'barcode', 'conversionFactor', 'purchasePrice', 'sellingPrice', 'minimumPrice', 'isBaseUnit'];
        $dbFields = ['sku', 'barcode', 'conversion_factor', 'purchase_price', 'selling_price', 'minimum_price', 'is_base_unit'];
        
        foreach ($props as $i => $prop) {
            if ($this->$prop !== null) {
                $data[$dbFields[$i]] = $this->$prop;
            }
        }
        return $data;
    }
}
