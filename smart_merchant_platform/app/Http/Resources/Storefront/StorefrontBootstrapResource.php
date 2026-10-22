<?php

namespace App\Http\Resources\Storefront;

use Illuminate\Http\Resources\Json\JsonResource;

class StorefrontBootstrapResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'storefront_slug' => $this->storefront_slug,
            'business_name' => $this->business_name,
            'display_name' => $this->storefront_display_name ?: $this->business_name,
            'logo_path' => $this->logo_path,
            'storefront_active' => (bool) $this->storefront_active,
            'whatsapp' => $this->storefront_whatsapp,
            'phone' => $this->storefront_phone ?: $this->primary_phone,
            'address_text' => $this->storefront_address_text,
            'lat' => $this->storefront_lat,
            'lng' => $this->storefront_lng,
            'theme_settings' => $this->storefront_theme_settings,
            'categories' => $this->storefront_categories,
        ];
    }
}
