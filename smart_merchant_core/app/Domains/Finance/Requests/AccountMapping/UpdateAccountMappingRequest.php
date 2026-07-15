<?php

namespace App\Domains\Finance\Requests\AccountMapping;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAccountMappingRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'chart_of_account_id' => 'required|uuid',
        ];
    }
}
