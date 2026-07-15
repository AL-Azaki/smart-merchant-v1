<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCurrencyRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name'          => ['sometimes', 'string', 'max:255'],
            'symbol'        => ['sometimes', 'string', 'max:10'],
            'exchange_rate' => ['sometimes', 'numeric', 'min:0'],
        ];
    }
}
