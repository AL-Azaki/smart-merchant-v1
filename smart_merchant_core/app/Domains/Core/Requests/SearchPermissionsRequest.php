<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SearchPermissionsRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'keyword'  => ['nullable', 'string', 'max:255'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by'  => ['nullable', 'string', 'in:id,name,group_name,created_at'],
            'sort_dir' => ['nullable', 'string', 'in:asc,desc,ASC,DESC'],
        ];
    }
}
