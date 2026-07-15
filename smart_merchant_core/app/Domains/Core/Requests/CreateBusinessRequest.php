<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateBusinessRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Will be handled by Policy
    }

    public function rules(): array
    {
        return [
            // Business Data
            'account_id'     => ['required', 'uuid', 'exists:accounts,id'],
            'business_name'  => ['required', 'string', 'max:255'],
            'business_type'  => ['nullable', 'string', 'max:100'],
            'primary_phone'  => ['required', 'string', 'max:30'],
            'primary_email'  => ['required', 'email', 'max:255'],
            'logo_path'      => ['nullable', 'string', 'max:500'],

            // Owner Data
            'owner_name'     => ['required', 'string', 'max:255'],
            'owner_email'    => ['required', 'email', 'max:255', 'unique:users,email'],
            'owner_username' => ['required', 'string', 'max:50'],
            'owner_password' => ['required', 'string', 'min:8'],

            // Plan & Currency
            'plan_id'        => ['required', 'uuid', 'exists:plans,id'],
            'currency_id'    => ['required', 'uuid', 'exists:currencies,id'],

            // Settings (Optional)
            'country'        => ['nullable', 'string', 'max:100'],
            'timezone'       => ['nullable', 'string', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'account_id.exists'     => 'The specified account does not exist.',
            'owner_email.unique'    => 'This email is already registered.',
            'plan_id.exists'        => 'The specified plan does not exist.',
            'currency_id.exists'    => 'The specified currency does not exist.',
            'owner_password.min'    => 'Password must be at least 8 characters.',
        ];
    }
}
