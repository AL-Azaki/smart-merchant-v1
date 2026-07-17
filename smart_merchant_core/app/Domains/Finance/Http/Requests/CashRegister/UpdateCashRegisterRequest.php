<?php

namespace App\Domains\Finance\Http\Requests\CashRegister;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCashRegisterRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'register_name' => 'sometimes|string|max:100',
        ];
    }
}
