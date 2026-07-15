<?php

namespace App\Domains\Sales\Http\Requests\SalesInvoice;

use Illuminate\Foundation\Http\FormRequest;

class CreateSalesInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'branch_id' => 'required|uuid',
            'customer_id' => 'nullable|uuid',
            'invoice_number' => 'required|string|max:50',
            'invoice_date' => 'required|date',
            'due_date' => 'nullable|date',
            'currency_id' => 'required|uuid',
            'exchange_rate' => 'required|numeric|min:0',
            'sub_total' => 'required|numeric|min:0',
            'discount_total' => 'required|numeric|min:0',
            'tax_total' => 'required|numeric|min:0',
            'grand_total' => 'required|numeric|min:0',
            'base_sub_total' => 'required|numeric|min:0',
            'base_discount_total' => 'required|numeric|min:0',
            'base_tax_total' => 'required|numeric|min:0',
            'base_grand_total' => 'required|numeric|min:0',
            'payment_status' => 'required|string|in:Unpaid,Partial,Paid',
            'notes' => 'nullable|string',
            
            'items' => 'required|array|min:1',
            'items.*.product_unit_id' => 'required|uuid',
            'items.*.warehouse_id' => 'required|uuid',
            'items.*.tax_id' => 'nullable|uuid',
            'items.*.quantity' => 'required|numeric|min:0.001',
            'items.*.unit_price' => 'required|numeric|min:0',
            'items.*.cost_price' => 'nullable|numeric|min:0',
            'items.*.discount' => 'required|numeric|min:0',
            'items.*.tax' => 'required|numeric|min:0',
            'items.*.line_total' => 'required|numeric|min:0',
            'items.*.cost_total' => 'nullable|numeric|min:0',
            'items.*.base_line_total' => 'required|numeric|min:0',
        ];
    }
}
