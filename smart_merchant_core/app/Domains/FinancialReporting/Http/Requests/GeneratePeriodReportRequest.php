<?php

namespace App\Domains\FinancialReporting\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class GeneratePeriodReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'business_id' => 'required|uuid',
            'period_id' => 'required|uuid',
        ];
    }
}
