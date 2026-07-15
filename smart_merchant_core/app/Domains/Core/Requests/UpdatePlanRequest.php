<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePlanRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name'           => ['sometimes', 'string', 'max:255'],
            'description'    => ['sometimes', 'nullable', 'string'],
            'monthly_price'  => ['sometimes', 'numeric', 'min:0'],
            'annual_price'   => ['sometimes', 'numeric', 'min:0'],
            'max_businesses' => ['sometimes', 'integer', 'min:1'],
            'max_users'      => ['sometimes', 'integer', 'min:1'],
            'features'       => ['sometimes', 'nullable', 'array'],
        ];
    }
}
