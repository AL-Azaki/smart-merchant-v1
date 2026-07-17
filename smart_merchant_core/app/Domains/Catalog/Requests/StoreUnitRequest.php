<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;

use Illuminate\Validation\Rule;

class StoreUnitRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'unit_name'        => [
                'required', 'string', 'max:100',
                Rule::unique('units', 'unit_name')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })
            ],
            'unit_symbol'      => [
                'required', 'string', 'max:10',
                Rule::unique('units', 'unit_symbol')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })
            ],
            'unit_description' => ['nullable', 'string'],
        ];
    }
}


