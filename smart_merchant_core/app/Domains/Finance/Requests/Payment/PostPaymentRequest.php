<?php

namespace App\Domains\Finance\Requests\Payment;

use Illuminate\Foundation\Http\FormRequest;

class PostPaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        $payment = $this->route('payment');
        return $this->user()->can('post', $payment);
    }

    public function rules(): array
    {
        return [];
    }
}
