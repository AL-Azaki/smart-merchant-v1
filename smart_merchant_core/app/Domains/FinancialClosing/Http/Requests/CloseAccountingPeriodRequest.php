<?php

namespace App\Domains\FinancialClosing\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CloseAccountingPeriodRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'user_id' => 'required|uuid|exists:users,id',
        ];
    }
}
