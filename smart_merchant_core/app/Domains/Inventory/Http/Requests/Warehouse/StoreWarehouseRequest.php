<?php

namespace App\Domains\Inventory\Http\Requests\Warehouse;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreWarehouseRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'branch_id' => ['required', 'uuid'],
            'warehouse_name' => ['required', 'string', 'max:255'],
            'warehouse_code' => [
                'required', 'string', 'max:100',
                Rule::unique('warehouses', 'warehouse_code')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })
            ],
            'address' => ['nullable', 'string', 'max:255'],
            'is_default' => ['nullable', 'boolean'],
            'is_active' => ['nullable', 'boolean'],
        ];
    }
}
