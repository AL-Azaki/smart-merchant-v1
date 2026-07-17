<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;

use Illuminate\Validation\Rule;

class UpdateUnitRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $id = $this->route('id');

        return [
            'unit_name'        => [
                'sometimes', 'required', 'string', 'max:100',
                Rule::unique('units', 'unit_name')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })->ignore($id)
            ],
            'unit_symbol'      => [
                'sometimes', 'required', 'string', 'max:10',
                Rule::unique('units', 'unit_symbol')->where(function ($query) {
                    return $query->where('business_id', $this->user()->business_id);
                })->ignore($id)
            ],
            'unit_description' => ['sometimes', 'nullable', 'string'],
        ];
    }
}


