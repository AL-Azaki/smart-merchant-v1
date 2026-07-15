<?php

namespace App\Domains\Finance\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChartOfAccountResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'account_code' => $this->account_code,
            'account_name' => $this->account_name,
            'description' => $this->description,
            'account_type' => new AccountTypeResource($this->whenLoaded('accountType')),
            'parent_account_id' => $this->parent_account_id,
            'parent_account' => new ChartOfAccountResource($this->whenLoaded('parent')),
            'currency_id' => $this->currency_id,
            'account_category' => $this->account_category,
            'normal_balance' => $this->normal_balance,
            'account_level' => $this->account_level,
            'allow_posting' => $this->allow_posting,
            'is_system' => $this->is_system,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
