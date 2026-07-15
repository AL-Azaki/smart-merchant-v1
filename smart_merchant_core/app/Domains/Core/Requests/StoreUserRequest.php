<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'full_name'   => ['required', 'string', 'max:255'],
            'username'    => ['required', 'string', 'max:255'],
            'email'       => ['required', 'email', 'max:255'],
            'password'    => ['required', 'string', 'min:8'],
            'language_id' => ['nullable', 'uuid'], // Should exist in languages table conceptually
            'timezone_id' => ['nullable', 'uuid'],
            'role_ids'    => ['nullable', 'array'],
            'role_ids.*'  => ['uuid'], // Further validation happens in Action/Repo
            'branch_ids'  => ['nullable', 'array'],
            'branch_ids.*'=> ['uuid'],
        ];
    }
}
