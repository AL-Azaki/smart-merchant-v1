<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AccountResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'account_name'   => $this->account_name,
            'account_number' => $this->account_number,
            'email'          => $this->email,
            'phone'          => $this->phone,
            'status'         => $this->status,
            'created_at'     => $this->created_at,
            'updated_at'     => $this->updated_at,
            'businesses'     => $this->whenLoaded('businesses'),
            'subscriptions'  => $this->whenLoaded('subscriptions'),
        ];
    }
}
