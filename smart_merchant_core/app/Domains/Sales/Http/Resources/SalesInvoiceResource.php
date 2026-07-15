<?php

namespace App\Domains\Sales\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SalesInvoiceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'branch_id' => $this->branch_id,
            'customer_id' => $this->customer_id,
            'invoice_number' => $this->invoice_number,
            'invoice_date' => $this->invoice_date,
            'due_date' => $this->due_date,
            'currency_id' => $this->currency_id,
            'exchange_rate' => (float) $this->exchange_rate,
            'sub_total' => (float) $this->sub_total,
            'discount_total' => (float) $this->discount_total,
            'tax_total' => (float) $this->tax_total,
            'grand_total' => (float) $this->grand_total,
            'base_sub_total' => (float) $this->base_sub_total,
            'base_discount_total' => (float) $this->base_discount_total,
            'base_tax_total' => (float) $this->base_tax_total,
            'base_grand_total' => (float) $this->base_grand_total,
            'payment_status' => $this->payment_status,
            'status' => $this->status,
            'notes' => $this->notes,
            'created_by' => $this->created_by,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'items' => SalesInvoiceItemResource::collection($this->whenLoaded('items')),
        ];
    }
}
