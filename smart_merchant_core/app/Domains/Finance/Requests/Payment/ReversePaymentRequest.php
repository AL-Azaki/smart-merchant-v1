<?php

namespace App\Domains\Finance\Requests\Payment;

use Illuminate\Foundation\Http\FormRequest;

class ReversePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        $payment = $this->route('payment');
        return $this->user()->can('reverse', $payment);
    }

    public function rules(): array
    {
        return [
            'reversal_reason' => 'required|string|max:255',
        ];
    }
}
