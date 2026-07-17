<?php

namespace App\Domains\Inventory\Http\Requests\InventoryTransaction;

use Illuminate\Foundation\Http\FormRequest;

class StoreTransactionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'branch_id' => ['required', 'uuid'],
            'warehouse_id' => ['required', 'uuid'],
            'transaction_type' => ['required', 'string', 'in:Receipt,Dispatch,Adjustment In,Adjustment Out,Opening Balance'],
            'movement_direction' => ['required', 'string', 'in:IN,OUT'],
            'reference_type' => ['nullable', 'string', 'in:SalesInvoice,SalesReturn,PurchaseInvoice,PurchaseReturn,Transfer,Adjustment'],
            'reference_id' => ['nullable', 'uuid'],
            'transaction_date' => ['nullable', 'date'],
        ];
    }
}
