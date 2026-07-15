<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePaymentTermRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'term_name' => 'required|string|max:100',
            'days_to_due' => 'required|integer|min:0',
        ];
    }
}
