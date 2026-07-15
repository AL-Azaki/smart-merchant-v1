<?php

namespace App\Domains\Finance\Requests\Payment;

use Illuminate\Foundation\Http\FormRequest;
use App\Domains\Finance\Models\Payment;

class CreatePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Payment::class);
    }

    public function rules(): array
    {
        return [
            'branch_id' => 'required|uuid|exists:branches,id',
            'payment_method_id' => 'required|uuid|exists:payment_methods,id',
            'chart_of_account_id' => 'required|uuid|exists:chart_of_accounts,id',
            'currency_id' => 'required|uuid|exists:currencies,id',
            'payment_number' => 'required|string|max:50',
            'payment_date' => 'required|date',
            'amount' => 'required|numeric|min:0.01',
            'base_amount' => 'required|numeric|min:0.01',
            'exchange_rate' => 'required|numeric|min:0.00000001',
            'payment_type' => 'required|string|in:Receipt,Payment,Refund,Adjustment,Transfer',
            'contact_type' => 'nullable|string|in:Customer,Supplier,Employee,Other',
            'contact_id' => 'nullable|uuid',
            'notes' => 'nullable|string',
            'allocations' => 'nullable|array',
            'allocations.*.amount' => 'required|numeric|min:0.01',
            'allocations.*.document_type' => 'required|string|max:50',
            'allocations.*.document_id' => 'required|uuid',
        ];
    }
}
