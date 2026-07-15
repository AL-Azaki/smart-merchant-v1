<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePlanRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name'           => ['required', 'string', 'max:255'],
            'description'    => ['nullable', 'string'],
            'monthly_price'  => ['required', 'numeric', 'min:0'],
            'annual_price'   => ['required', 'numeric', 'min:0'],
            'max_businesses' => ['required', 'integer', 'min:1'],
            'max_users'      => ['required', 'integer', 'min:1'],
            'features'       => ['nullable', 'array'],
        ];
    }
}
