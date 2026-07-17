<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreCategoryRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'category_name' => [
                'required', 'string', 'max:100',
                Rule::unique('categories', 'category_name')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })
            ],
            'category_code' => [
                'nullable', 'string', 'max:50',
                Rule::unique('categories', 'category_code')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })
            ],
            'parent_id' => ['nullable', 'uuid'],
            'description' => ['nullable', 'string', 'max:500'],
            'image_path' => ['nullable', 'string', 'max:500'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
        ];
    }
}
