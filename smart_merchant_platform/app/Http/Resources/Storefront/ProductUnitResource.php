<?php

namespace App\Http\Resources\Storefront;

use Illuminate\Http\Resources\Json\JsonResource;

class ProductUnitResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'unit_id' => $this->unit_id,
            'is_base_unit' => $this->is_base_unit,
            'conversion_factor' => $this->conversion_factor,
            'barcode' => $this->barcode,
            'selling_price' => (float) $this->selling_price,
            'inventory_quantity' => $this->when(isset($this->inventory_quantity), (float) $this->inventory_quantity),
        ];
    }
}
