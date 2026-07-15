<?php

namespace App\Domains\Inventory\Http\Requests\InventoryTransaction;

use Illuminate\Foundation\Http\FormRequest;

class CreateInventoryTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'warehouse_id' => 'required|uuid',
            'transaction_type' => 'required|string|in:Receipt,Dispatch,Adjustment In,Adjustment Out',
            'reference_type' => 'nullable|string|in:SalesInvoice,SalesReturn,PurchaseInvoice,PurchaseReturn,Transfer,Adjustment',
            'reference_id' => 'nullable|uuid',
            'transaction_date' => 'nullable|date',
            'notes' => 'nullable|string',
            'lines' => 'required|array|min:1',
            'lines.*.product_unit_id' => 'required|uuid',
            'lines.*.line_number' => 'required|integer|min:1',
            'lines.*.quantity' => 'required|numeric|min:0.001',
            'lines.*.unit_cost' => 'required|numeric|min:0',
        ];
    }
}
