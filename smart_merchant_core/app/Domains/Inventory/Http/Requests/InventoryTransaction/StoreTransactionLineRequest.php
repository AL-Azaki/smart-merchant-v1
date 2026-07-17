<?php

namespace App\Domains\Inventory\Http\Requests\InventoryTransaction;

use Illuminate\Foundation\Http\FormRequest;

class StoreTransactionLineRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'product_unit_id' => ['required', 'uuid'],
            'quantity' => ['required', 'numeric', 'gt:0'],
            'unit_cost' => ['nullable', 'numeric', 'min:0'],
        ];
    }
}
