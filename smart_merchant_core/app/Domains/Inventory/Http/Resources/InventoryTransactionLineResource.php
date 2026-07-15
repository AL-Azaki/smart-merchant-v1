<?php

namespace App\Domains\Inventory\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InventoryTransactionLineResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'product_unit_id' => $this->product_unit_id,
            'line_number' => $this->line_number,
            'quantity' => (float) $this->quantity,
            'unit_cost' => (float) $this->unit_cost,
        ];
    }
}
