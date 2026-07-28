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
            'email' => 'nullable|email|max:255',
            'address' => 'nullable|string',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.product_unit_id' => 'required|uuid',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'idempotency_key' => 'required|string|max:255',
        ];
    }
}
