<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAccountRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'account_name' => ['sometimes', 'string', 'max:255'],
            'email'        => ['sometimes', 'email', 'max:255'],
            'phone'        => ['sometimes', 'nullable', 'string', 'max:30'],
        ];
    }
}
