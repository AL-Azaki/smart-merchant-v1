<?php

namespace App\Domains\Sales\Http\Requests\SalesInvoice;

use Illuminate\Foundation\Http\FormRequest;

class UpdateSalesInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'branch_id' => 'sometimes|required|uuid',
            'customer_id' => 'nullable|uuid',
            'invoice_number' => 'sometimes|required|string|max:50',
            'invoice_date' => 'sometimes|required|date',
            'due_date' => 'nullable|date',
            'currency_id' => 'sometimes|required|uuid',
            'exchange_rate' => 'sometimes|required|numeric|min:0',
            'sub_total' => 'sometimes|required|numeric|min:0',
            'discount_total' => 'sometimes|required|numeric|min:0',
            'tax_total' => 'sometimes|required|numeric|min:0',
            'grand_total' => 'sometimes|required|numeric|min:0',
            'base_sub_total' => 'sometimes|required|numeric|min:0',
            'base_discount_total' => 'sometimes|required|numeric|min:0',
            'base_tax_total' => 'sometimes|required|numeric|min:0',
            'base_grand_total' => 'sometimes|required|numeric|min:0',
            'payment_status' => 'sometimes|required|string|in:Unpaid,Partial,Paid',
            'notes' => 'nullable|string',
            
            'items' => 'sometimes|required|array|min:1',
            'items.*.product_unit_id' => 'required_with:items|uuid',
            'items.*.warehouse_id' => 'required_with:items|uuid',
            'items.*.tax_id' => 'nullable|uuid',
            'items.*.quantity' => 'required_with:items|numeric|min:0.001',
            'items.*.unit_price' => 'required_with:items|numeric|min:0',
            'items.*.cost_price' => 'nullable|numeric|min:0',
            'items.*.discount' => 'required_with:items|numeric|min:0',
            'items.*.tax' => 'required_with:items|numeric|min:0',
            'items.*.line_total' => 'required_with:items|numeric|min:0',
            'items.*.cost_total' => 'nullable|numeric|min:0',
            'items.*.base_line_total' => 'required_with:items|numeric|min:0',
        ];
    }
}
