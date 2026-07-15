<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SubscriptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'account_id'     => $this->account_id,
            'plan_id'        => $this->plan_id,
            'currency_id'    => $this->currency_id,
            'currency_code'  => $this->currency_code,
            'plan_name'      => $this->plan_name,
            'billing_cycle'  => $this->billing_cycle,
            'price'          => $this->price,
            'max_businesses' => $this->max_businesses,
            'max_users'      => $this->max_users,
            'features'       => is_string($this->features) ? json_decode($this->features, true) : $this->features,
            'status'         => $this->status,
            'close_reason'   => $this->close_reason,
            'trial_ends_at'  => $this->trial_ends_at,
            'starts_at'      => $this->starts_at,
            'ends_at'        => $this->ends_at,
            'created_at'     => $this->created_at,
            'updated_at'     => $this->updated_at,
            'plan'           => new PlanResource($this->whenLoaded('plan')),
            'currency'       => new CurrencyResource($this->whenLoaded('currency')),
            'account'        => new AccountResource($this->whenLoaded('account')),
        ];
    }
}
