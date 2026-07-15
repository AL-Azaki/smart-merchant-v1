<?php

namespace App\Domains\Finance\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class AccountMappingResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'mapping_type' => $this->mapping_type,
            'chart_of_account_id' => $this->chart_of_account_id,
            'created_at' => $this->created_at ? $this->created_at->toIso8601String() : null,
            'updated_at' => $this->updated_at ? $this->updated_at->toIso8601String() : null,
        ];
    }
}
