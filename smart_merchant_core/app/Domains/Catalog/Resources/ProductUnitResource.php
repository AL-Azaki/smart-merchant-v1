<?php

namespace App\Domains\Catalog\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductUnitResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'product_id' => $this->product_id,
            'unit_id' => $this->unit_id,
            'sku' => $this->sku,
            'barcode' => $this->barcode,
            'conversion_factor' => $this->conversion_factor,
            'purchase_price' => $this->purchase_price,
            'selling_price' => $this->selling_price,
            'minimum_price' => $this->minimum_price,
            'is_base_unit' => $this->is_base_unit,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'deleted_at' => $this->deleted_at,
            'unit' => new UnitResource($this->whenLoaded('unit')),
            // BranchProductPrices will be loaded when needed
        ];
    }
}
