<?php

namespace App\Domains\Inventory\Http\Requests\Inventory;

use Illuminate\Foundation\Http\FormRequest;

class UpdateInventoryRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'alert_quantity' => ['required', 'numeric', 'min:0'],
        ];
    }
}
