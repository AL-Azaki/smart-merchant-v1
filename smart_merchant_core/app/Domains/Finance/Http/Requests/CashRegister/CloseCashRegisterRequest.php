<?php

namespace App\Domains\Finance\Http\Requests\CashRegister;

use Illuminate\Foundation\Http\FormRequest;

class CloseCashRegisterRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'actual_balance' => 'required|numeric|min:0',
        ];
    }
}
