<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreSubscriptionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'plan_id'       => ['required', 'uuid'],
            'currency_id'   => ['required', 'uuid'],
            'billing_cycle' => ['required', 'string', 'in:monthly,annual'],
            'trial_ends_at' => ['nullable', 'date', 'after:now'],
        ];
    }
}
