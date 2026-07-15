<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BusinessResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'account_id' => $this->account_id,
            'business_name' => $this->business_name,
            'business_type' => $this->business_type,
            'primary_phone' => $this->primary_phone,
            'primary_email' => $this->primary_email,
            'logo_path' => $this->logo_path,
            'status' => $this->status,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
