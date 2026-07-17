<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductUnitRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $id = $this->route('id');

        return [
            'sku' => [
                'sometimes', 'nullable', 'string', 'max:100',
                Rule::unique('product_units', 'sku')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })->ignore($id)
            ],
            'barcode' => [
                'sometimes', 'nullable', 'string', 'max:100',
                Rule::unique('product_units', 'barcode')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })->ignore($id)
            ],
            'conversion_factor' => ['sometimes', 'required', 'numeric', 'min:0.0001'],
            'purchase_price' => ['sometimes', 'required', 'numeric', 'min:0'],
            'selling_price' => ['sometimes', 'required', 'numeric', 'min:0'],
            'minimum_price' => ['sometimes', 'required', 'numeric', 'min:0'],
            'is_base_unit' => ['sometimes', 'required', 'boolean'],
        ];
    }
}
