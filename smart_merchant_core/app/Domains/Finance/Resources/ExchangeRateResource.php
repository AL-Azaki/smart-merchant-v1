<?php

namespace App\Domains\Finance\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ExchangeRateResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'source_currency_id' => $this->source_currency_id,
            'target_currency_id' => $this->target_currency_id,
            'effective_date' => $this->effective_date ? $this->effective_date->format('Y-m-d') : null,
            'rate' => (float) $this->rate,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            
            // Optional loaded relations
            'source_currency' => $this->whenLoaded('sourceCurrency'),
            'target_currency' => $this->whenLoaded('targetCurrency'),
        ];
    }
}
