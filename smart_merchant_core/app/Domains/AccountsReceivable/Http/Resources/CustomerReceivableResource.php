<?php

namespace App\Domains\AccountsReceivable\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CustomerReceivableResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'customer_id' => $this->customer_id,
            'branch_id' => $this->branch_id,
            'currency_id' => $this->currency_id,
            'status' => $this->status,
            'current_balance' => $this->current_balance,
            'credit_limit' => $this->credit_limit,
            'due_date' => $this->due_date,
            'responsible_user_id' => $this->responsible_user_id,
            'entries' => ReceivableEntryResource::collection($this->whenLoaded('entries')),
        ];
    }
}
