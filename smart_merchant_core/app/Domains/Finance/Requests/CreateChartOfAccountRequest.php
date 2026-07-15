<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateChartOfAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Authorized in controller via Policy
    }

    public function rules(): array
    {
        return [
            'account_type_id' => 'required|integer|exists:account_types,id',
            'account_name' => 'required|string|max:255',
            'normal_balance' => 'required|string|in:Debit,Credit',
            'account_code' => 'nullable|string|max:50',
            'parent_account_id' => 'nullable|uuid|exists:chart_of_accounts,id',
            'currency_id' => 'nullable|uuid|exists:currencies,id',
            'description' => 'nullable|string',
            'account_category' => 'nullable|string|max:100',
            'allow_posting' => 'boolean',
            'is_active' => 'boolean',
        ];
    }
}
