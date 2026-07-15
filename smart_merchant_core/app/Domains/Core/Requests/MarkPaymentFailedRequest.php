<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MarkPaymentFailedRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'failure_reason' => ['nullable', 'string', 'max:255'],
        ];
    }
}
