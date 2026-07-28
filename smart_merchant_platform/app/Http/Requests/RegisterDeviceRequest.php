<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterDeviceRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'business_id' => 'required|uuid|exists:businesses,id',
            'device_uuid' => 'required|string|max:255',
            'device_name' => 'nullable|string|max:255',
            'platform' => 'nullable|string|max:100',
            'app_version' => 'nullable|string|max:50',
        ];
    }
}
