<?php

namespace App\Domains\Inventory\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InventoryTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'warehouse_id' => $this->warehouse_id,
            'transaction_type' => $this->transaction_type,
            'status' => $this->status,
            'reference_type' => $this->reference_type,
            'reference_id' => $this->reference_id,
            'transaction_date' => $this->transaction_date,
            'notes' => $this->notes,
            'created_by' => $this->created_by,
            'posted_by' => $this->posted_by,
            'posted_at' => $this->posted_at,
            'reversed_by' => $this->reversed_by,
            'reversed_at' => $this->reversed_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'lines' => InventoryTransactionLineResource::collection($this->whenLoaded('lines')),
        ];
    }
}
