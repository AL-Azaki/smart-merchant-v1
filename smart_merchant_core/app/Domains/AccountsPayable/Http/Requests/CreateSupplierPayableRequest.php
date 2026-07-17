<?php

namespace App\Domains\AccountsPayable\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateSupplierPayableRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'business_id' => 'required|uuid|exists:businesses,id',
            'supplier_id' => 'required|uuid|exists:suppliers,id',
            'branch_id' => 'nullable|uuid|exists:branches,id',
            'currency_id' => 'required|uuid|exists:currencies,id',
            'due_date' => 'nullable|date',
            'responsible_user_id' => 'nullable|uuid|exists:users,id',
        ];
    }
}
