<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProductUnitRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'product_id' => ['required', 'uuid'],
            'unit_id' => ['required', 'uuid'],
            'sku' => [
                'nullable', 'string', 'max:100',
                Rule::unique('product_units', 'sku')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })
            ],
            'barcode' => [
                'nullable', 'string', 'max:100',
                Rule::unique('product_units', 'barcode')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })
            ],
            'conversion_factor' => ['required', 'numeric', 'min:0.0001'],
            'purchase_price' => ['required', 'numeric', 'min:0'],
            'selling_price' => ['required', 'numeric', 'min:0'],
            'minimum_price' => ['required', 'numeric', 'min:0'],
            'is_base_unit' => ['nullable', 'boolean'],
        ];
    }
}
