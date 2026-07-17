<?php

namespace App\Domains\AccountsPayable\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class PayableEntryResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'supplier_payable_id' => $this->supplier_payable_id,
            'entry_type' => $this->entry_type,
            'direction' => $this->direction,
            'amount' => $this->amount,
            'foreign_currency_amount' => $this->foreign_currency_amount,
            'foreign_currency_code' => $this->foreign_currency_code,
            'exchange_rate' => $this->exchange_rate,
            'document_type' => $this->document_type,
            'document_id' => $this->document_id,
            'created_at' => $this->created_at,
        ];
    }
}
