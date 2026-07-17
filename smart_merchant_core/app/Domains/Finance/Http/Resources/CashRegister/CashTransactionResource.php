<?php

namespace App\Domains\Finance\Http\Resources\CashRegister;

use Illuminate\Http\Resources\Json\JsonResource;

class CashTransactionResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'transaction_type' => $this->transaction_type,
            'amount' => $this->amount,
            'document_type' => $this->document_type,
            'document_id' => $this->document_id,
            'notes' => $this->notes,
            'created_at' => $this->created_at,
        ];
    }
}
