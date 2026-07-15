<?php

namespace App\Domains\Finance\Resources\Payment;

use Illuminate\Http\Resources\Json\JsonResource;

class PaymentAllocationResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'payment_id' => $this->payment_id,
            'amount' => $this->amount,
            'document_type' => $this->document_type,
            'document_id' => $this->document_id,
        ];
    }
}
