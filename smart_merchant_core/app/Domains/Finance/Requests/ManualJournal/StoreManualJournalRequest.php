<?php

namespace App\Domains\Finance\Requests\ManualJournal;

use Illuminate\Foundation\Http\FormRequest;

class StoreManualJournalRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'business_id' => 'required|uuid',
            'fiscal_period_id' => 'required|uuid',
            'document_date' => 'required|date',
            'posting_date' => 'required|date',
            'currency_id' => 'required|uuid',
            'exchange_rate' => 'required|numeric|min:0.00000001',
            'description' => 'nullable|string|max:1000',
            'lines' => 'required|array|min:2',
            'lines.*.chart_of_account_id' => 'required|uuid',
            'lines.*.type' => 'required|string|in:Debit,Credit',
            'lines.*.foreign_amount' => 'required|numeric|min:0.01',
            'lines.*.base_amount' => 'required|numeric|min:0.01',
            'lines.*.description' => 'nullable|string|max:1000',
        ];
    }
}
