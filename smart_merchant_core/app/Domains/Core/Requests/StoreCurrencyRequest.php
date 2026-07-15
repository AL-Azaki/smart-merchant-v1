<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCurrencyRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name'          => ['required', 'string', 'max:255'],
            'code'          => ['required', 'string', 'max:10', 'unique:currencies,code'],
            'symbol'        => ['required', 'string', 'max:10'],
            'exchange_rate' => ['nullable', 'numeric', 'min:0'],
        ];
    }
}
