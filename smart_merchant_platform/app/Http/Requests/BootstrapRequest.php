<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BootstrapRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'business_id' => 'nullable|uuid|exists:businesses,id',
            'branch_id' => 'nullable|uuid|exists:branches,id',
            'device_uuid' => 'nullable|string',
        ];
    }
}
