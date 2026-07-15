<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BranchResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'branch_name' => $this->branch_name,
            'branch_code' => $this->branch_code,
            'phone' => $this->phone,
            'email' => $this->email,
            'address' => $this->address,
            'is_default' => $this->is_default,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
