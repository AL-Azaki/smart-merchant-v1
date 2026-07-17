<?php

namespace App\Domains\FixedAssets\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DepreciationScheduleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'fixed_asset_id' => $this->fixed_asset_id,
            'depreciation_period' => $this->depreciation_period,
            'scheduled_posting_date' => $this->scheduled_posting_date?->toDateString(),
            'depreciation_amount' => $this->depreciation_amount,
            'base_depreciation_amount' => $this->base_depreciation_amount,
            'accumulated_depreciation' => $this->accumulated_depreciation,
            'base_accumulated_depreciation' => $this->base_accumulated_depreciation,
            'remaining_book_value' => $this->remaining_book_value,
            'base_remaining_book_value' => $this->base_remaining_book_value,
            'status' => $this->status,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
