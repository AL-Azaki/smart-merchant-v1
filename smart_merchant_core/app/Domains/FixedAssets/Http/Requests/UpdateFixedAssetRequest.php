<?php

namespace App\Domains\FixedAssets\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateFixedAssetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'branch_id' => 'nullable|uuid',
            'asset_category_id' => 'nullable|uuid',
            'asset_name' => 'sometimes|string|max:255',
            'acquisition_cost' => 'sometimes|numeric|min:0',
            'base_acquisition_cost' => 'sometimes|numeric|min:0',
            'useful_life' => 'sometimes|integer|min:1',
            'residual_value' => 'sometimes|numeric|min:0',
            'base_residual_value' => 'sometimes|numeric|min:0',
            'depreciation_method' => 'sometimes|string|max:50',
            'depreciation_start_date' => 'sometimes|date',
            'responsible_user_id' => 'nullable|uuid|exists:users,id',
        ];
    }
}
