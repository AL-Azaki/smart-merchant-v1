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
            'logo_path' => $this->logo_path,
        ];
    }
}
