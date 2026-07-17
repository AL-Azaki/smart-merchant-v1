<?php

namespace App\Domains\Finance\Http\Resources\BankAccount;

use Illuminate\Http\Resources\Json\JsonResource;

class BankAccountResource extends JsonResource
{
    public function toArray($request)
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
            'status' => $this->status,
            'is_default' => $this->is_default,
            'opening_balance' => $this->opening_balance,
            'opening_balance_date' => $this->opening_balance_date,
            'current_balance' => $this->current_balance,
            'last_reconciled_balance' => $this->last_reconciled_balance,
            'last_reconciled_at' => $this->last_reconciled_at,
            'transactions' => BankTransactionResource::collection($this->whenLoaded('transactions')),
        ];
    }
}
