<?php

namespace App\Domains\Finance\Http\Requests\CashRegister;

use Illuminate\Foundation\Http\FormRequest;

class CreateCashRegisterRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'business_id' => 'required|uuid',
            'branch_id' => 'required|uuid',
            'currency_id' => 'required|uuid',
            'register_name' => 'required|string|max:100',
        ];
    }
}
