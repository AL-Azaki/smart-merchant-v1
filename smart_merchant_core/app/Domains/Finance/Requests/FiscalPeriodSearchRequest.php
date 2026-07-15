<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class FiscalPeriodSearchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'fiscal_year_id' => 'nullable|uuid|exists:fiscal_years,id',
            'name' => 'nullable|string|max:100',
            'status' => 'nullable|string|in:Open,Closed',
            'per_page' => 'nullable|integer|min:1|max:100',
        ];
    }
}
