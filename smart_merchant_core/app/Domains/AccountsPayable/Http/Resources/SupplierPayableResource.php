<?php

namespace App\Domains\AccountsPayable\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class SupplierPayableResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'supplier_id' => $this->supplier_id,
            'branch_id' => $this->branch_id,
            'currency_id' => $this->currency_id,
            'status' => $this->status,
            'current_balance' => $this->current_balance,
            'due_date' => $this->due_date,
            'responsible_user_id' => $this->responsible_user_id,
            'entries' => PayableEntryResource::collection($this->whenLoaded('entries')),
        ];
    }
}
