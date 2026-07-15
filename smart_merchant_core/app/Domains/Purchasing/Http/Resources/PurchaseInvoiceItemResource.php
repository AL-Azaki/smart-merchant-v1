<?php

namespace App\Domains\Purchasing\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PurchaseInvoiceItemResource extends JsonResource
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
            'discount' => (float) $this->discount,
            'tax' => (float) $this->tax,
            'line_total' => (float) $this->line_total,
        ];
    }
}
