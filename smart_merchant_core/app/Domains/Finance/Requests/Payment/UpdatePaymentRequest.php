<?php

namespace App\Domains\Finance\Requests\Payment;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        $payment = $this->route('payment');
        return $this->user()->can('update', $payment);
    }

    public function rules(): array
    {
        return [
            'payment_method_id' => 'sometimes|uuid|exists:payment_methods,id',
            'chart_of_account_id' => 'sometimes|uuid|exists:chart_of_accounts,id',
            'amount' => 'sometimes|numeric|min:0.01',
            'base_amount' => 'sometimes|numeric|min:0.01',
            'notes' => 'nullable|string',
            'allocations' => 'nullable|array',
            'allocations.*.amount' => 'required|numeric|min:0.01',
            'allocations.*.document_type' => 'required|string|max:50',
            'allocations.*.document_id' => 'required|uuid',
        ];
    }
}
