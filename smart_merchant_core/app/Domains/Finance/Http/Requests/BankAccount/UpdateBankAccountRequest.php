<?php

namespace App\Domains\Finance\Http\Requests\BankAccount;

use Illuminate\Foundation\Http\FormRequest;

class UpdateBankAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'branch_id' => 'nullable|uuid|exists:branches,id',
            'account_number' => 'nullable|string|max:50',
            'iban' => 'nullable|string|max:50',
            'bank_name' => 'nullable|string|max:100',
            'display_name' => 'nullable|string|max:100',
            'description' => 'nullable|string',
            'is_default' => 'nullable|boolean',
        ];
    }
}
