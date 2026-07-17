<?php

namespace App\Domains\FinancialClosing\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateAccountingPeriodRequest extends FormRequest
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
            'period_name' => 'required|string|max:100',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'created_by' => 'required|uuid',
        ];
    }
}
