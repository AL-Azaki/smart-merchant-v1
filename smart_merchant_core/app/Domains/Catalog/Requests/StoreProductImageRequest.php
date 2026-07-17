<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreProductImageRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'product_id' => ['required', 'uuid'],
            'image_path' => ['required', 'string', 'max:500'],
            'is_primary' => ['nullable', 'boolean'],
        ];
    }
}
