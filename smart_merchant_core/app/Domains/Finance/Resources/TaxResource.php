<?php

namespace App\Domains\Finance\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaxResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'tax_name' => $this->tax_name,
            'tax_rate' => (float) $this->tax_rate,
            'is_active' => (bool) $this->is_active,
        ];
    }
}
