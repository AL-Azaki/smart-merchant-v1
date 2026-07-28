<?php

namespace App\Http\Resources\Storefront;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'order_number' => $this->order_number,
            'order_date' => $this->order_date,
            'status' => $this->status,
            'payment_status' => $this->payment_status,
            'sub_total' => $this->sub_total,
            'tax_total' => $this->tax_total,
            'grand_total' => $this->grand_total,
            'notes' => $this->notes,
        ];
    }
}
