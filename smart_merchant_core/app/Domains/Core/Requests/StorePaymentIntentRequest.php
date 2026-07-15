<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePaymentIntentRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'payment_method' => ['required', 'string', 'max:50'], // e.g., 'credit_card', 'bank_transfer'
        ];
    }
}
