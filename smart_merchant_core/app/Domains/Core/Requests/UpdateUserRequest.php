<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateUserRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'full_name'   => ['sometimes', 'string', 'max:255'],
            'username'    => ['sometimes', 'string', 'max:255'],
            'language_id' => ['sometimes', 'nullable', 'uuid'],
            'timezone_id' => ['sometimes', 'nullable', 'uuid'],
        ];
    }
}
