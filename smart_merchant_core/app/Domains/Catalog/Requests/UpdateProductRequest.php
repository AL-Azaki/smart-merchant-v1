<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $id = $this->route('id');

        return [
            'product_code' => [
                'sometimes', 'required', 'string', 'max:100',
                Rule::unique('products', 'product_code')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })->ignore($id)
            ],
            'product_name' => ['sometimes', 'required', 'string', 'max:255'],
            'category_id' => ['sometimes', 'nullable', 'uuid'],
            'brand_id' => ['sometimes', 'nullable', 'uuid'],
            'tax_id' => ['sometimes', 'nullable', 'uuid'],
            'product_type' => ['sometimes', 'nullable', 'string', 'max:50'],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ];
    }
}
