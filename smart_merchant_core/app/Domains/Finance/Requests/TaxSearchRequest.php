<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TaxSearchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tax_name' => 'nullable|string|max:100',
            'is_active' => 'nullable|boolean',
            'per_page' => 'nullable|integer|min:1|max:100',
        ];
    }
}
