<?php

namespace App\Domains\Finance\Http\Requests\CashRegister;

use Illuminate\Foundation\Http\FormRequest;

class OpenCashRegisterRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'opening_balance' => 'required|numeric|min:0',
        ];
    }
}
