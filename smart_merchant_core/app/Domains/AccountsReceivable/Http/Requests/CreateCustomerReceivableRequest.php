<?php

namespace App\Domains\AccountsReceivable\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateCustomerReceivableRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'business_id' => 'required|uuid|exists:businesses,id',
            'customer_id' => 'required|uuid|exists:customers,id',
            'branch_id' => 'nullable|uuid|exists:branches,id',
            'currency_id' => 'required|uuid|exists:currencies,id',
            'credit_limit' => 'nullable|numeric|min:0',
            'due_date' => 'nullable|date',
            'responsible_user_id' => 'nullable|uuid|exists:users,id',
        ];
    }
}
