<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateCategoryRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $id = $this->route('id');

        return [
            'category_name' => [
                'sometimes', 'required', 'string', 'max:100',
                Rule::unique('categories', 'category_name')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })->ignore($id)
            ],
            'category_code' => [
                'sometimes', 'nullable', 'string', 'max:50',
                Rule::unique('categories', 'category_code')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })->ignore($id)
            ],
            'parent_id' => ['sometimes', 'nullable', 'uuid'],
            'description' => ['sometimes', 'nullable', 'string', 'max:500'],
            'image_path' => ['sometimes', 'nullable', 'string', 'max:500'],
            'sort_order' => ['sometimes', 'nullable', 'integer', 'min:0'],
        ];
    }
}
