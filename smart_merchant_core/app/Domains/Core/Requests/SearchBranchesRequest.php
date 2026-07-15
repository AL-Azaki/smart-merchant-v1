<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SearchBranchesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'keyword'    => ['nullable', 'string', 'max:255'],
            'is_active'  => ['nullable', 'boolean'],
            'is_default' => ['nullable', 'boolean'],
            'per_page'   => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by'    => ['nullable', 'string', 'in:created_at,branch_name,branch_code,is_default'],
            'sort_dir'   => ['nullable', 'string', 'in:asc,desc,ASC,DESC'],
            'include'    => ['nullable', 'string'],
        ];
    }
}
