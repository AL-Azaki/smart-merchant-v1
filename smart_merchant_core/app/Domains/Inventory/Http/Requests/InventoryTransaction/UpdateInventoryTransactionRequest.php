<?php

namespace App\Domains\Inventory\Http\Requests\InventoryTransaction;

use Illuminate\Foundation\Http\FormRequest;

class UpdateInventoryTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'warehouse_id' => 'sometimes|required|uuid',
            'transaction_type' => 'sometimes|required|string|in:Receipt,Dispatch,Adjustment In,Adjustment Out',
            'reference_type' => 'nullable|string|in:SalesInvoice,SalesReturn,PurchaseInvoice,PurchaseReturn,Transfer,Adjustment',
            'reference_id' => 'nullable|uuid',
            'transaction_date' => 'sometimes|required|date',
            'notes' => 'nullable|string',
            'lines' => 'sometimes|required|array|min:1',
            'lines.*.product_unit_id' => 'required_with:lines|uuid',
            'lines.*.line_number' => 'required_with:lines|integer|min:1',
            'lines.*.quantity' => 'required_with:lines|numeric|min:0.001',
            'lines.*.unit_cost' => 'required_with:lines|numeric|min:0',
        ];
    }
}
