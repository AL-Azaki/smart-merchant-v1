<?php

namespace App\Domains\Finance\Http\Resources\BankAccount;

use Illuminate\Http\Resources\Json\JsonResource;

class BankTransactionResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'bank_account_id' => $this->bank_account_id,
            'transaction_type' => $this->transaction_type,
            'direction' => $this->direction,
            'amount' => $this->amount,
            'foreign_currency_amount' => $this->foreign_currency_amount,
            'foreign_currency_code' => $this->foreign_currency_code,
            'exchange_rate' => $this->exchange_rate,
            'document_type' => $this->document_type,
            'document_id' => $this->document_id,
            'bank_transfer_id' => $this->bank_transfer_id,
            'reconciliation_status' => $this->reconciliation_status,
            'notes' => $this->notes,
            'created_at' => $this->created_at,
        ];
    }
}
