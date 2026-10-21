<?php

namespace App\Http\Resources\Storefront;

use App\Models\ProductImage;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductListResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $primaryImage = null;
        if ($this->relationLoaded('images')) {
            $primary = $this->images->firstWhere('is_primary', true) ?? $this->images->first();
            $primaryImage = $primary ? ProductImage::sanitizePublicImageUrl($primary->image_path) : null;
        }

        $minPrice = null;
        if ($this->relationLoaded('units')) {
            $activeUnits = $this->units->where('is_active', true);
            $minPrice = $activeUnits->min('selling_price');
        }

        return [
            'id' => $this->id,
            'product_name' => $this->product_name,
            'product_code' => $this->product_code,
            'description' => $this->description,
            'category_id' => $this->category_id,
            'brand_id' => $this->brand_id,
            'category_name' => $this->relationLoaded('category') ? $this->category?->category_name : null,
            'brand_name' => $this->relationLoaded('brand') ? $this->brand?->brand_name : null,
            'primary_image' => $primaryImage,
            'selling_price' => $minPrice !== null ? (float) $minPrice : null,
            'images' => $this->whenLoaded('images', function () {
                return $this->images->map(function ($image) {
                    $sanitized = ProductImage::sanitizePublicImageUrl($image->image_path);

                    return [
                        'id' => $image->id,
                        'image_path' => $sanitized,
                        'is_primary' => (bool) $image->is_primary,
                        'has_fallback' => $sanitized === null,
                    ];
                });
            }),
            'units' => ProductUnitResource::collection($this->whenLoaded('units')),
        ];
    }
}
