<?php

namespace App\Domains\AccountsPayable\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RecordPayableEntryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'business_id' => 'required|uuid|exists:businesses,id',
            'entry_type' => 'required|string|in:Invoice,Payment,Credit Note,Debit Note,Adjustment,Write-off',
            'direction' => 'required|string|in:Debit,Credit',
            'amount' => 'required|numeric|gt:0',
            'foreign_currency_amount' => 'nullable|numeric',
            'foreign_currency_code' => 'nullable|string|size:3',
            'exchange_rate' => 'nullable|numeric',
            'document_type' => 'nullable|string',
            'document_id' => 'nullable|uuid',
        ];
    }
}
