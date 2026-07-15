<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SyncUserBranchesRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return [
            'branch_ids'   => ['required', 'array'],
            'branch_ids.*' => ['uuid'],
        ];
    }
}
