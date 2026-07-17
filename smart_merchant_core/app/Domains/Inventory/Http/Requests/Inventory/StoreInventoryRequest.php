<?php

namespace App\Domains\Inventory\Http\Requests\Inventory;

use Illuminate\Foundation\Http\FormRequest;

class StoreInventoryRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'warehouse_id' => ['required', 'uuid'],
            'product_unit_id' => ['required', 'uuid'],
            'alert_quantity' => ['nullable', 'numeric', 'min:0'],
            // quantity and average_cost are strictly system-managed, but initial 0s or explicit 0s are allowed if defined by business rule.
            // But per requirements, users MUST NOT modify quantity/average_cost.
            // We will enforce that users can only pass alert_quantity, warehouse_id, product_unit_id.
        ];
    }
}
