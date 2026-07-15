<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ExchangeRateSearchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'source_currency_id' => 'nullable|uuid|exists:currencies,id',
            'target_currency_id' => 'nullable|uuid|exists:currencies,id',
            'effective_date' => 'nullable|date',
            'per_page' => 'nullable|integer|min:1|max:100',
        ];
    }
}
