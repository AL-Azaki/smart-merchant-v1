<?php

namespace App\Domains\Finance\Requests\AccountMapping;

use Illuminate\Foundation\Http\FormRequest;

class StoreAccountMappingRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'business_id' => 'required|uuid',
            'mapping_type' => 'required|string|max:50',
            'chart_of_account_id' => 'required|uuid',
        ];
    }
}
