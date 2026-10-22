<?php

namespace App\Http\Resources\Platform;

use App\Services\Storefront\StorefrontSettingsService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StorefrontSettingsResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $slug = $this->storefront_slug;

        return [
            'storefront_active' => (bool) $this->storefront_active,
            'storefront_display_name' => $this->storefront_display_name,
            'effective_display_name' => ! empty($this->storefront_display_name)
                ? $this->storefront_display_name
                : $this->business_name,
            'storefront_slug' => $slug,
            'store_url' => StorefrontSettingsService::buildStoreUrl($slug),
            'storefront_whatsapp' => $this->storefront_whatsapp,
            'storefront_phone' => $this->storefront_phone,
            'effective_phone' => ! empty($this->storefront_phone)
                ? $this->storefront_phone
                : $this->primary_phone,
            'storefront_address_text' => $this->storefront_address_text,
            'storefront_lat' => $this->storefront_lat !== null ? (float) $this->storefront_lat : null,
            'storefront_lng' => $this->storefront_lng !== null ? (float) $this->storefront_lng : null,
            'storefront_theme_settings' => $this->storefront_theme_settings ?: null,
            'storefront_categories' => $this->storefront_categories ?: null,
        ];
    }

    /**
     * Get additional data that should be returned with the resource array.
     *
     * @return array<string, mixed>
     */
    public function with(Request $request): array
    {
        return [
            'success' => true,
        ];
    }
}
