<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ViewBranchRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Authorization is delegated strictly to the Policy
        return true;
    }

    public function rules(): array
    {
        return [
            'include' => ['nullable', 'string']
        ];
    }
}
