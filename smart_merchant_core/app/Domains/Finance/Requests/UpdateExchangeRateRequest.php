<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Domains\Core\Models\Currency;

class UpdateExchangeRateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'source_currency_id' => [
                'required',
                'uuid',
                'exists:currencies,id',
                function ($attribute, $value, $fail) {
                    $currency = Currency::find($value);
                    if ($currency && !$currency->is_active) {
                        $fail("The source currency must be active.");
                    }
                },
            ],
            'target_currency_id' => [
                'required',
                'uuid',
                'exists:currencies,id',
                'different:source_currency_id',
                function ($attribute, $value, $fail) {
                    $currency = Currency::find($value);
                    if ($currency && !$currency->is_active) {
                        $fail("The target currency must be active.");
                    }
                },
            ],
            'effective_date' => 'required|date',
            'rate' => 'required|numeric|gt:0',
        ];
    }
}
