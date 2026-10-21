<?php

namespace App\Http\Requests\Sync;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateOrderStatusRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $prohibited = [
            'business_id',
            'customer_id',
            'customer_name',
            'customer_phone',
            'customer_email',
            'shipping_address',
            'shipping_city',
            'customer_notes',
            'items',
            'product_id',
            'product_unit_id',
            'quantity',
            'unit_price',
            'subtotal',
            'sub_total',
            'tax',
            'tax_total',
            'discount',
            'discount_total',
            'grand_total',
            'source',
            'channel_id',
            'order_number',
            'order_date',
            'currency_id',
        ];

        $rules = [
            'status' => 'required|string|in:Confirmed,Cancelled,Delivered',
            'idempotency_key' => 'required|string|max:255',
            'invoice_id' => 'nullable|string|max:100',
            'invoice_number' => 'nullable|string|max:100',
            'completed_at' => 'nullable|date',
            'revision' => 'nullable|integer',
        ];

        foreach ($prohibited as $field) {
            $rules[$field] = 'prohibited';
        }

        return $rules;
    }

    /**
     * Custom messages for validation errors.
     */
    public function messages(): array
    {
        return [
            'status.in' => 'The status must be one of: Confirmed, Cancelled, Delivered.',
            '*.prohibited' => 'Field :attribute cannot be modified via status feedback.',
        ];
    }
}
