<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAccountRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'account_name'   => ['required', 'string', 'max:255'],
            'email'          => ['required', 'email', 'max:255'],
            'phone'          => ['nullable', 'string', 'max:30'],
            'account_number' => ['nullable', 'string', 'max:50'],
        ];
    }
}
