<?php

namespace App\Domains\Purchasing\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PurchaseInvoiceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'branch_id' => $this->branch_id,
            'supplier_id' => $this->supplier_id,
            'warehouse_id' => $this->warehouse_id,
            'invoice_number' => $this->invoice_number,
            'purchase_date' => $this->purchase_date,
            'due_date' => $this->due_date,
            'currency_id' => $this->currency_id,
            'exchange_rate' => (float) $this->exchange_rate,
            'sub_total' => (float) $this->sub_total,
            'discount_total' => (float) $this->discount_total,
            'tax_total' => (float) $this->tax_total,
            'grand_total' => (float) $this->grand_total,
            'payment_status' => $this->payment_status,
            'status' => $this->status,
            'notes' => $this->notes,
            'created_by' => $this->created_by,
            'posted_by' => $this->posted_by,
            'posted_at' => $this->posted_at,
            'reversed_by' => $this->reversed_by,
            'reversed_at' => $this->reversed_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'items' => PurchaseInvoiceItemResource::collection($this->whenLoaded('items')),
        ];
    }
}
