<?php

namespace App\Domains\FixedAssets\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreFixedAssetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'business_id' => 'required|uuid|exists:businesses,id',
            'branch_id' => 'nullable|uuid',
            'asset_category_id' => 'nullable|uuid',
            'currency_id' => 'required|uuid|exists:currencies,id',
            'asset_code' => 'required|string|max:50',
            'asset_name' => 'required|string|max:255',
            'acquisition_date' => 'required|date',
            'acquisition_cost' => 'required|numeric|min:0',
            'base_acquisition_cost' => 'required|numeric|min:0',
            'useful_life' => 'required|integer|min:1',
            'residual_value' => 'nullable|numeric|min:0',
            'base_residual_value' => 'nullable|numeric|min:0',
            'depreciation_method' => 'required|string|max:50',
            'depreciation_start_date' => 'required|date',
            'responsible_user_id' => 'nullable|uuid|exists:users,id',
        ];
    }
}
