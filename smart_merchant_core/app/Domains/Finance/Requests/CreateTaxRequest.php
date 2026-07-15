<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateTaxRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tax_name' => 'required|string|max:100',
            'tax_rate' => 'required|numeric|min:0',
        ];
    }
}
