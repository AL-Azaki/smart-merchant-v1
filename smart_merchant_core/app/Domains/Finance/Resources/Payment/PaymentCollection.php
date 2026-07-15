<?php

namespace App\Domains\Finance\Resources\Payment;

use Illuminate\Http\Resources\Json\ResourceCollection;

class PaymentCollection extends ResourceCollection
{
    public function toArray($request): array
    {
        return [
            'data' => PaymentResource::collection($this->collection),
        ];
    }
}
