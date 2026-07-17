<?php

namespace App\Domains\FixedAssets\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FixedAssetResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'branch_id' => $this->branch_id,
            'asset_category_id' => $this->asset_category_id,
            'currency_id' => $this->currency_id,
            'asset_code' => $this->asset_code,
            'asset_name' => $this->asset_name,
            'acquisition_date' => $this->acquisition_date?->toDateString(),
            'acquisition_cost' => $this->acquisition_cost,
            'base_acquisition_cost' => $this->base_acquisition_cost,
            'useful_life' => $this->useful_life,
            'residual_value' => $this->residual_value,
            'base_residual_value' => $this->base_residual_value,
            'depreciation_method' => $this->depreciation_method,
            'depreciation_start_date' => $this->depreciation_start_date?->toDateString(),
            'status' => $this->status,
            'responsible_user_id' => $this->responsible_user_id,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'depreciation_schedules' => DepreciationScheduleResource::collection(
                $this->whenLoaded('depreciationSchedules')
            ),
        ];
    }
}
