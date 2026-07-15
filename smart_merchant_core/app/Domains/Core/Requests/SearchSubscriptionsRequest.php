<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SearchSubscriptionsRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'keyword'  => ['nullable', 'string', 'max:255'],
            'status'   => ['nullable', 'string', 'in:Pending,Active,Suspended,Expired,Cancelled,Closed'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by'  => ['nullable', 'string', 'in:created_at,starts_at,ends_at,price'],
            'sort_dir' => ['nullable', 'string', 'in:asc,desc,ASC,DESC'],
        ];
    }
}
