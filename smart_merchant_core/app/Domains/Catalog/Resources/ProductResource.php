<?php

namespace App\Domains\Catalog\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'category_id' => $this->category_id,
            'brand_id' => $this->brand_id,
            'tax_id' => $this->tax_id,
            'product_type' => $this->product_type,
            'product_code' => $this->product_code,
            'product_name' => $this->product_name,
            'description' => $this->description,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'deleted_at' => $this->deleted_at,
            'category' => new CategoryResource($this->whenLoaded('category')),
            // We will load ProductUnits later
        ];
    }
}
