<?php

namespace App\Domains\Finance\Http\Requests\BankAccount;

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
            'business_id' => 'required|uuid|exists:businesses,id',
            'branch_id' => 'nullable|uuid|exists:branches,id',
            'currency_id' => 'required|uuid|exists:currencies,id',
            'account_number' => 'required|string|max:50',
            'iban' => 'nullable|string|max:50',
            'bank_name' => 'required|string|max:100',
            'display_name' => 'nullable|string|max:100',
            'description' => 'nullable|string',
            'is_default' => 'nullable|boolean',
            'opening_balance' => 'nullable|numeric',
            'opening_balance_date' => 'nullable|date',
        ];
    }
}
