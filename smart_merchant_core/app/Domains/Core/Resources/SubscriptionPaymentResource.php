<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SubscriptionPaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'subscription_id' => $this->subscription_id,
            'amount'          => $this->amount,
            'currency_code'   => $this->currency_code,
            'plan_name'       => $this->plan_name,
            'payment_method'  => $this->payment_method,
            'status'          => $this->status,
            'transaction_id'  => $this->transaction_id,
            'receipt_url'     => $this->receipt_url,
            'failure_reason'  => $this->failure_reason,
            'created_at'      => $this->created_at,
            'updated_at'      => $this->updated_at,
        ];
    }
}
