<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProductRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'product_code' => [
                'required', 'string', 'max:100',
                Rule::unique('products', 'product_code')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })
            ],
            'product_name' => ['required', 'string', 'max:255'],
            'category_id' => ['nullable', 'uuid'],
            'brand_id' => ['nullable', 'uuid'],
            'tax_id' => ['nullable', 'uuid'],
            'product_type' => ['nullable', 'string', 'max:50'],
            'description' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
