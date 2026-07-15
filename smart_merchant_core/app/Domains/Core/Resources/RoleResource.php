<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RoleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'          => $this->id,
            'business_id' => $this->business_id,
            'name'        => $this->name,
            'description' => $this->description,
            'is_system'   => (bool) $this->is_system,
            'created_at'  => $this->created_at,
            'updated_at'  => $this->updated_at,
            'permissions' => PermissionResource::collection($this->whenLoaded('permissions')),
        ];
    }
}
