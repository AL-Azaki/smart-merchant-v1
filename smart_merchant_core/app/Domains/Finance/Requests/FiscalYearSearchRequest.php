<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class FiscalYearSearchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'code' => 'nullable|string|max:20',
            'name' => 'nullable|string|max:100',
            'status' => 'nullable|string|in:Open,Closed',
            'per_page' => 'nullable|integer|min:1|max:100',
        ];
    }
}
