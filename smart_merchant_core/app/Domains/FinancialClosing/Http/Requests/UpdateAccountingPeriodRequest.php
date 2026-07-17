<?php

namespace App\Domains\FinancialClosing\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAccountingPeriodRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'period_name' => 'nullable|string|max:100',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'updated_by' => 'required|uuid',
        ];
    }
}
