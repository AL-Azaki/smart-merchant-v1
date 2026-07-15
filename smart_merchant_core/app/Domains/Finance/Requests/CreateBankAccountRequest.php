<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateBankAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'currency_id' => 'required|uuid|exists:currencies,id',
            'branch_id' => 'nullable|uuid|exists:branches,id',
            'account_number' => 'required|string|max:50',
            'iban' => 'nullable|string|max:50',
            'bank_name' => 'required|string|max:100',
            'display_name' => 'nullable|string|max:100',
            'description' => 'nullable|string',
            'is_default' => 'nullable|boolean',
        ];
    }
}
