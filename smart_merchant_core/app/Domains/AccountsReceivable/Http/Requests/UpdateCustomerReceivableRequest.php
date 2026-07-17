<?php

namespace App\Domains\AccountsReceivable\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCustomerReceivableRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'credit_limit' => 'nullable|numeric|min:0',
            'due_date' => 'nullable|date',
            'responsible_user_id' => 'nullable|uuid|exists:users,id',
        ];
    }
}
