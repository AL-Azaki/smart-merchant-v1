<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateChartOfAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'account_name' => 'required|string|max:255',
            'account_code' => 'nullable|string|max:50',
            'parent_account_id' => 'nullable|uuid|exists:chart_of_accounts,id',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ];
    }
}
