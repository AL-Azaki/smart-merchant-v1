<?php

namespace App\Domains\Purchasing\Http\Requests\PurchaseInvoice;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePurchaseInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'branch_id' => 'sometimes|required|uuid',
            'supplier_id' => 'sometimes|required|uuid',
            'warehouse_id' => 'sometimes|required|uuid',
            'invoice_number' => 'sometimes|required|string|max:50',
            'purchase_date' => 'nullable|date',
            'due_date' => 'nullable|date',
            'currency_id' => 'sometimes|required|uuid',
            'exchange_rate' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
            'items' => 'sometimes|required|array|min:1',
            'items.*.product_unit_id' => 'required_with:items|uuid',
            'items.*.warehouse_id' => 'required_with:items|uuid',
            'items.*.tax_id' => 'nullable|uuid',
            'items.*.quantity' => 'required_with:items|numeric|min:0.001',
            'items.*.unit_price' => 'required_with:items|numeric|min:0',
            'items.*.discount' => 'nullable|numeric|min:0',
            'items.*.tax' => 'nullable|numeric|min:0',
        ];
    }
}
