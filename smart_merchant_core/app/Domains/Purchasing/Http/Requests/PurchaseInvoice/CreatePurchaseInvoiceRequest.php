<?php

namespace App\Domains\Purchasing\Http\Requests\PurchaseInvoice;

use Illuminate\Foundation\Http\FormRequest;

class CreatePurchaseInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'branch_id' => 'required|uuid',
            'supplier_id' => 'required|uuid',
            'warehouse_id' => 'required|uuid',
            'invoice_number' => 'required|string|max:50',
            'purchase_date' => 'nullable|date',
            'due_date' => 'nullable|date',
            'currency_id' => 'required|uuid',
            'exchange_rate' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.product_unit_id' => 'required|uuid',
            'items.*.warehouse_id' => 'required|uuid',
            'items.*.tax_id' => 'nullable|uuid',
            'items.*.quantity' => 'required|numeric|min:0.001',
            'items.*.unit_price' => 'required|numeric|min:0',
            'items.*.discount' => 'nullable|numeric|min:0',
            'items.*.tax' => 'nullable|numeric|min:0',
        ];
    }
}
