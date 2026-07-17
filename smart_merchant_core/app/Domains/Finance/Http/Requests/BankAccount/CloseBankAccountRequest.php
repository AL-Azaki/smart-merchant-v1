<?php

namespace App\Domains\Finance\Http\Requests\BankAccount;

use Illuminate\Foundation\Http\FormRequest;

class CloseBankAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [];
    }
}
