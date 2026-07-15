<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateBranchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'branch_name' => ['sometimes', 'string', 'max:255'],
            'branch_code' => ['sometimes', 'string', 'max:50'],
            'phone'       => ['sometimes', 'nullable', 'string', 'max:30'],
            'email'       => ['sometimes', 'nullable', 'email', 'max:255'],
            'address'     => ['sometimes', 'nullable', 'string'],
        ];
    }
}
