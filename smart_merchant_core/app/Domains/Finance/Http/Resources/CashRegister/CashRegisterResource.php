<?php

namespace App\Domains\Finance\Http\Resources\CashRegister;

use Illuminate\Http\Resources\Json\JsonResource;

class CashRegisterResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'branch_id' => $this->branch_id,
            'currency_id' => $this->currency_id,
            'register_name' => $this->register_name,
            'status' => $this->status,
            'current_balance' => $this->current_balance,
            'transactions' => CashTransactionResource::collection($this->whenLoaded('transactions')),
        ];
    }
}
