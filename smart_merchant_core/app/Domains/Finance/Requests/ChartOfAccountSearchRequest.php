<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ChartOfAccountSearchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'nullable|string|max:255',
            'code' => 'nullable|string|max:50',
            'status' => 'nullable|boolean',
            'account_type_id' => 'nullable|integer|exists:account_types,id',
            'per_page' => 'nullable|integer|min:1|max:100',
        ];
    }
}
