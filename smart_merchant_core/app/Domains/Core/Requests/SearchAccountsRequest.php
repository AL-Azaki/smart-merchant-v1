<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SearchAccountsRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'keyword'  => ['nullable', 'string', 'max:255'],
            'status'   => ['nullable', 'string', 'in:Active,Suspended,Closed'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by'  => ['nullable', 'string', 'in:created_at,account_name'],
            'sort_dir' => ['nullable', 'string', 'in:asc,desc,ASC,DESC'],
        ];
    }
}
