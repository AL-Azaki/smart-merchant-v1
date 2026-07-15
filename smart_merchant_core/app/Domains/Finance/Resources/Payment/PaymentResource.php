<?php

namespace App\Domains\Finance\Resources\Payment;

use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'branch_id' => $this->branch_id,
            'payment_number' => $this->payment_number,
            'payment_date' => $this->payment_date,
            'payment_method_id' => $this->payment_method_id,
            'chart_of_account_id' => $this->chart_of_account_id,
            'currency_id' => $this->currency_id,
            'exchange_rate' => $this->exchange_rate,
            'amount' => $this->amount,
            'base_amount' => $this->base_amount,
            'payment_type' => $this->payment_type,
            'contact_type' => $this->contact_type,
            'contact_id' => $this->contact_id,
            'status' => $this->status,
            'notes' => $this->notes,
            'created_by' => $this->created_by,
            'posted_by' => $this->posted_by,
            'posted_at' => $this->posted_at,
            'reversed_by' => $this->reversed_by,
            'reversed_at' => $this->reversed_at,
            'reversal_reason' => $this->reversal_reason,
            'allocations' => PaymentAllocationResource::collection($this->whenLoaded('allocations')),
        ];
    }
}
