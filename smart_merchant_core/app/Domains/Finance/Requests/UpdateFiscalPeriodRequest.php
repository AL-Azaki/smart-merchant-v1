<?php

namespace App\Domains\Finance\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateFiscalPeriodRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'period_name' => 'required|string|max:100',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
        ];
    }
}
