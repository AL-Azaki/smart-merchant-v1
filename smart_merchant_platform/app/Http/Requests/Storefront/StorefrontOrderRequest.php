<?php

namespace App\Http\Requests\Storefront;

use Illuminate\Foundation\Http\FormRequest;

class StorefrontOrderRequest extends FormRequest
{
    public function authorize()
    {
        return true; // We validate the storefront identifier in the service/controller
    }

    public function rules()
    {
        return [
            'customer_name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:50',
            'customer_phone' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'customer_email' => 'nullable|email|max:255',
            'address' => 'nullable|string',
            'shipping_address' => 'nullable|string',
            'city' => 'nullable|string|max:100',
            'shipping_city' => 'nullable|string|max:100',
            'notes' => 'nullable|string',
            'customer_notes' => 'nullable|string',
            'source' => 'nullable|string|max:50',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'nullable|uuid',
            'items.*.product_unit_id' => 'required|uuid',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'idempotency_key' => 'required|string|max:255',
        ];
    }
}
