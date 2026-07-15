<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PlanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'name'           => $this->name,
            'description'    => $this->description,
            'monthly_price'  => $this->monthly_price,
            'annual_price'   => $this->annual_price,
            'max_businesses' => $this->max_businesses,
            'max_users'      => $this->max_users,
            'features'       => is_string($this->features) ? json_decode($this->features, true) : $this->features,
            'is_active'      => (bool) $this->is_active,
            'created_at'     => $this->created_at,
            'updated_at'     => $this->updated_at,
        ];
    }
}
