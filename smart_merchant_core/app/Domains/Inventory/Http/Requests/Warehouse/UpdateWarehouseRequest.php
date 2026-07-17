<?php

namespace App\Domains\Inventory\Http\Requests\Warehouse;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateWarehouseRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $id = $this->route('id');

        return [
            'branch_id' => ['sometimes', 'required', 'uuid'],
            'warehouse_name' => ['sometimes', 'required', 'string', 'max:255'],
            'warehouse_code' => [
                'sometimes', 'required', 'string', 'max:100',
                Rule::unique('warehouses', 'warehouse_code')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })->ignore($id)
            ],
            'address' => ['sometimes', 'nullable', 'string', 'max:255'],
            'is_default' => ['sometimes', 'required', 'boolean'],
            'is_active' => ['sometimes', 'required', 'boolean'],
        ];
    }
}
