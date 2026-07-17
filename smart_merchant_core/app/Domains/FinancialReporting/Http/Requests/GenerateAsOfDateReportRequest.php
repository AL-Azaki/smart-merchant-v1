<?php

namespace App\Domains\FinancialReporting\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class GenerateAsOfDateReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'business_id' => 'required|uuid',
            'as_of_date' => 'required|date',
        ];
    }
}
