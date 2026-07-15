<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SyncUserRolesRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return [
            'role_ids'   => ['required', 'array'],
            'role_ids.*' => ['uuid'],
        ];
    }
}
