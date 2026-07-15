<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'          => $this->id,
            'business_id' => $this->business_id,
            'full_name'   => $this->full_name,
            'username'    => $this->username,
            'email'       => $this->email,
            'status'      => $this->status,
            'language_id' => $this->language_id,
            'timezone_id' => $this->timezone_id,
            'created_at'  => $this->created_at,
            'updated_at'  => $this->updated_at,
            // Only loaded if requested in Includes
            'roles'       => $this->whenLoaded('roles'),
            'branches'    => $this->whenLoaded('branches'),
        ];
    }
}
