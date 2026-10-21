<?php

namespace App\Http\Resources\Storefront;

use App\Models\ProductImage;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductDetailResource extends JsonResource
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

        return [
            'id' => $this->id,
            'product_name' => $this->product_name,
            'product_code' => $this->product_code,
            'description' => $this->description,
            'category_id' => $this->category_id,
            'brand_id' => $this->brand_id,
            'category' => new CategoryResource($this->whenLoaded('category')),
            'brand' => $this->whenLoaded('brand', function () {
                return [
                    'id' => $this->brand?->id,
                    'brand_name' => $this->brand?->brand_name,
                    'logo_path' => $this->brand?->logo_path,
                ];
            }),
            'primary_image' => $primaryImage,
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
