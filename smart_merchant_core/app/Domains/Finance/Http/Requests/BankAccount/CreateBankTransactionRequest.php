<?php

namespace App\Domains\Finance\Http\Requests\BankAccount;

use Illuminate\Foundation\Http\FormRequest;

class CreateBankTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'business_id' => 'required|uuid|exists:businesses,id',
            'transaction_type' => 'required|string|in:Deposit,Withdrawal,Transfer In,Transfer Out,Adjustment,Bank Fee,Interest,Opening Balance',
            'direction' => 'required|string|in:Credit,Debit',
            'amount' => 'required|numeric|gt:0',
            'foreign_currency_amount' => 'nullable|numeric',
            'foreign_currency_code' => 'nullable|string|max:3',
            'exchange_rate' => 'nullable|numeric',
            'document_type' => 'nullable|string',
            'document_id' => 'nullable|uuid',
            'bank_transfer_id' => 'nullable|uuid',
            'notes' => 'nullable|string',
        ];
    }
}
