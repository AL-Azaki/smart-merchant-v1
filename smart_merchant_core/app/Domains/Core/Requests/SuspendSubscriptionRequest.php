<?php

namespace App\Domains\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SuspendSubscriptionRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array { return []; }
}
