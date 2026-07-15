<?php

namespace App\Domains\Sales\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SalesInvoiceItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'product_unit_id' => $this->product_unit_id,
            'warehouse_id' => $this->warehouse_id,
            'tax_id' => $this->tax_id,
            'quantity' => (float) $this->quantity,
            'unit_price' => (float) $this->unit_price,
            'cost_price' => (float) $this->cost_price,
            'discount' => (float) $this->discount,
            'tax' => (float) $this->tax,
            'line_total' => (float) $this->line_total,
            'cost_total' => (float) $this->cost_total,
            'base_line_total' => (float) $this->base_line_total,
        ];
    }
}
