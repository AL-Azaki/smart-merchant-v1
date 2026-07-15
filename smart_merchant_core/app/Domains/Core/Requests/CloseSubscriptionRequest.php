<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CloseSubscriptionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'close_reason' => ['required', 'string', 'in:upgraded,downgraded,renewed'],
        ];
    }
}
