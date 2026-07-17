<?php

namespace App\Domains\GeneralLedger\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateJournalEntryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'business_id' => 'required|uuid',
            'fiscal_year_id' => 'required|uuid',
            'fiscal_period_id' => 'required|uuid',
            'journal_number' => 'required|string|max:50',
            'document_date' => 'required|date',
            'posting_date' => 'nullable|date',
            'journal_type' => 'required|string|max:50',
            'document_type' => 'nullable|string|max:50',
            'document_id' => 'nullable|uuid',
            'document_number' => 'nullable|string|max:50',
            'currency_id' => 'required|uuid',
            'exchange_rate' => 'required|numeric',
            'description' => 'nullable|string',
            'created_by' => 'required|uuid',
            
            'lines' => 'required|array|min:2',
            'lines.*.line_number' => 'required|integer',
            'lines.*.chart_of_account_id' => 'required|uuid',
            'lines.*.description' => 'nullable|string',
            'lines.*.currency_id' => 'required|uuid',
            'lines.*.exchange_rate' => 'required|numeric',
            'lines.*.type' => 'required|in:Debit,Credit',
            'lines.*.foreign_amount' => 'required|numeric|min:0',
            'lines.*.base_amount' => 'required|numeric|min:0',
            'lines.*.document_type' => 'nullable|string|max:50',
            'lines.*.document_id' => 'nullable|uuid',
        ];
    }
}
