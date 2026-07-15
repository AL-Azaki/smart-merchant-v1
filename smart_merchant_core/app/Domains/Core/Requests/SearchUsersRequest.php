<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SearchUsersRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'keyword'  => ['nullable', 'string', 'max:255'],
            'status'   => ['nullable', 'string', 'in:Active,Suspended'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by'  => ['nullable', 'string', 'in:created_at,full_name,username,email'],
            'sort_dir' => ['nullable', 'string', 'in:asc,desc,ASC,DESC'],
            'include'  => ['nullable', 'string'],
        ];
    }
}
