<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreBranchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Authorization handled by Policy
    }

    public function rules(): array
    {
        return [
            'business_id' => ['required', 'uuid', 'exists:businesses,id'],
            'branch_name' => ['required', 'string', 'max:255'],
            'branch_code' => ['required', 'string', 'max:50'],
            'phone'       => ['nullable', 'string', 'max:30'],
            'email'       => ['nullable', 'email', 'max:255'],
            'address'     => ['nullable', 'string'],
            'is_active'   => ['nullable', 'boolean'],
        ];
    }
}
