<?php

namespace App\Domains\AccountsPayable\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateSupplierPayableRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'due_date' => 'nullable|date',
            'responsible_user_id' => 'nullable|uuid|exists:users,id',
        ];
    }
}
