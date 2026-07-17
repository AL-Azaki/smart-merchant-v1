<?php

namespace App\Domains\Finance\Http\Requests\CashRegister;

use Illuminate\Foundation\Http\FormRequest;

class CreateCashTransactionRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'transaction_type' => 'required|string|in:Deposit,Withdrawal,Transfer In,Transfer Out,Adjustment,Payment,Receipt',
            'amount' => 'required|numeric|min:0.01',
            'document_type' => 'nullable|string',
            'document_id' => 'nullable|uuid',
            'notes' => 'nullable|string',
        ];
    }
}
