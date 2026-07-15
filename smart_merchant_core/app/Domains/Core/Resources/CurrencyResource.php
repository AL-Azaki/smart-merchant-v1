<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CurrencyResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'            => $this->id,
            'name'          => $this->name,
            'code'          => $this->code,
            'symbol'        => $this->symbol,
            'exchange_rate' => $this->exchange_rate, // @todo: Will be removed when ExchangeRate entity is implemented
            'is_default'    => (bool) $this->is_default,
            'is_active'     => (bool) $this->is_active,
            'created_at'    => $this->created_at,
            'updated_at'    => $this->updated_at,
        ];
    }
}
