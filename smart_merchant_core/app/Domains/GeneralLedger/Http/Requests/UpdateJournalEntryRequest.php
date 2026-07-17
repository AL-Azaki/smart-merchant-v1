<?php

namespace App\Domains\GeneralLedger\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateJournalEntryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'document_date' => 'nullable|date',
            'posting_date' => 'nullable|date',
            'description' => 'nullable|string',
            
            'lines' => 'nullable|array|min:2',
            'lines.*.line_number' => 'required_with:lines|integer',
            'lines.*.chart_of_account_id' => 'required_with:lines|uuid',
            'lines.*.description' => 'nullable|string',
            'lines.*.currency_id' => 'required_with:lines|uuid',
            'lines.*.exchange_rate' => 'required_with:lines|numeric',
            'lines.*.type' => 'required_with:lines|in:Debit,Credit',
            'lines.*.foreign_amount' => 'required_with:lines|numeric|min:0',
            'lines.*.base_amount' => 'required_with:lines|numeric|min:0',
            'lines.*.document_type' => 'nullable|string|max:50',
            'lines.*.document_id' => 'nullable|uuid',
        ];
    }
}
