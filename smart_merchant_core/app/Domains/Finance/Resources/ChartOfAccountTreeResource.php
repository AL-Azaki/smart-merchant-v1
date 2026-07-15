<?php

namespace App\Domains\Finance\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChartOfAccountTreeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'account_code' => $this->account_code,
            'account_name' => $this->account_name,
            'parent_account_id' => $this->parent_account_id,
            'account_type' => new AccountTypeResource($this->whenLoaded('accountType')),
            'account_level' => $this->account_level,
            'allow_posting' => $this->allow_posting,
            'is_system' => $this->is_system,
            'is_active' => $this->is_active,
        ];
    }
}
