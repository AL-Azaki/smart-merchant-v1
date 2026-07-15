<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SearchPlansRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'keyword'   => ['nullable', 'string', 'max:255'],
            'is_active' => ['nullable', 'boolean'],
            'per_page'  => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by'   => ['nullable', 'string', 'in:monthly_price,annual_price,name,created_at'],
            'sort_dir'  => ['nullable', 'string', 'in:asc,desc,ASC,DESC'],
        ];
    }
}
