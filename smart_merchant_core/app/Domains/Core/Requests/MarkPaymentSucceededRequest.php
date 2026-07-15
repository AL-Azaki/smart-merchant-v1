<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MarkPaymentSucceededRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'transaction_id' => ['nullable', 'string', 'max:255'],
            'receipt_url'    => ['nullable', 'url', 'max:1024'],
        ];
    }
}
