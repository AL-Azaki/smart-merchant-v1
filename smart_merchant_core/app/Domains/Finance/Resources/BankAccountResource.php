<?php

namespace App\Domains\Finance\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BankAccountResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'branch_id' => $this->branch_id,
            'currency_id' => $this->currency_id,
            'account_number' => $this->account_number,
            'iban' => $this->iban,
            'bank_name' => $this->bank_name,
            'display_name' => $this->display_name,
            'description' => $this->description,
            'is_active' => (bool) $this->is_active,
            'is_default' => (bool) $this->is_default,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
