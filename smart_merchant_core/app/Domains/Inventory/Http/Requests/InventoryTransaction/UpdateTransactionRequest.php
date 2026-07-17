<?php

namespace App\Domains\Inventory\Http\Requests\InventoryTransaction;

use Illuminate\Foundation\Http\FormRequest;

class UpdateTransactionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'reference_type' => ['nullable', 'string', 'in:SalesInvoice,SalesReturn,PurchaseInvoice,PurchaseReturn,Transfer,Adjustment'],
            'reference_id' => ['nullable', 'uuid'],
            'transaction_date' => ['nullable', 'date'],
        ];
    }
}
